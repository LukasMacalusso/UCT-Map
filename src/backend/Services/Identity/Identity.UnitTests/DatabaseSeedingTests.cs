using Identity.Domain.Entities;
using Identity.Infrastructure.Identity;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace Identity.UnitTests;

public sealed class DatabaseSeedingTests
{
    private const string AdminEmail = "admin@uct.cl";
    private const string AdminPassword = "Seed-Admin-Password1!";

    private static readonly IdentitySeedSettings ConfiguredSeed = new()
    {
        AdminEmail = AdminEmail,
        AdminPassword = AdminPassword
    };

    [Fact]
    public async Task EnsureAdminAsync_WhenNoAdminExists_CreatesConfiguredAdmin()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();

        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);

        var admin = await userManager.FindByEmailAsync(AdminEmail);
        Assert.NotNull(admin);
        Assert.Equal("Admin UCT", admin.Name);
        Assert.True(await userManager.IsInRoleAsync(admin, Role.Admin));
        Assert.True(await userManager.CheckPasswordAsync(admin, AdminPassword));
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenRunTwice_KeepsSingleAdmin()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();

        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);
        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);

        Assert.Single(await userManager.GetUsersInRoleAsync(Role.Admin));
    }

    [Theory]
    [InlineData(null, AdminPassword)]
    [InlineData(AdminEmail, null)]
    [InlineData(" ", " ")]
    public async Task EnsureAdminAsync_WhenCredentialsAreNotConfigured_DoesNotCreateAdmin(
        string? email,
        string? password)
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();

        await RoleSeeder.EnsureAdminAsync(
            userManager,
            new IdentitySeedSettings { AdminEmail = email, AdminPassword = password },
            NullLogger.Instance);

        Assert.Empty(userManager.Users);
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenActiveAdminExists_DoesNotPromoteSeedAccount()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        await CreateUserAsync(userManager, "other-admin@uct.cl", Role.Admin);
        var demotedSeedUser = await CreateUserAsync(userManager, AdminEmail, Role.Teacher);

        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);

        Assert.False(await userManager.IsInRoleAsync(demotedSeedUser, Role.Admin));
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenSeedAccountExists_KeepsItsPassword()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var existing = await CreateUserAsync(userManager, AdminEmail, Role.Teacher);

        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);

        Assert.True(await userManager.IsInRoleAsync(existing, Role.Admin));
        Assert.True(await userManager.CheckPasswordAsync(existing, "Password123!"));
        Assert.False(await userManager.CheckPasswordAsync(existing, AdminPassword));
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenSeedAccountIsSuspended_DoesNotReactivateIt()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var suspended = await CreateUserAsync(userManager, AdminEmail, Role.Admin);
        suspended.SetSuspended(true);
        await userManager.UpdateAsync(suspended);

        await RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, NullLogger.Instance);

        Assert.True((await userManager.FindByEmailAsync(AdminEmail))!.IsSuspended);
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenPasswordIsRejected_ThrowsWithoutLeakingIt()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        const string weakPassword = "weak";

        var exception = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            RoleSeeder.EnsureAdminAsync(
                userManager,
                new IdentitySeedSettings { AdminEmail = AdminEmail, AdminPassword = weakPassword },
                NullLogger.Instance));

        Assert.DoesNotContain(weakPassword, exception.Message);
        Assert.Contains("PasswordTooShort", exception.Message);
        Assert.Null(await userManager.FindByEmailAsync(AdminEmail));
    }

    [Fact]
    public async Task EnsureAdminAsync_WhenArgumentsAreNull_Throws()
    {
        using var provider = await CreateSeededServicesAsync();
        var userManager = provider.GetRequiredService<UserManager<User>>();

        await Assert.ThrowsAsync<ArgumentNullException>(() =>
            RoleSeeder.EnsureAdminAsync(null!, ConfiguredSeed, NullLogger.Instance));
        await Assert.ThrowsAsync<ArgumentNullException>(() =>
            RoleSeeder.EnsureAdminAsync(userManager, null!, NullLogger.Instance));
        await Assert.ThrowsAsync<ArgumentNullException>(() =>
            RoleSeeder.EnsureAdminAsync(userManager, ConfiguredSeed, null!));
    }

    [Fact]
    public async Task InitializeAsync_WhenDatabaseIsNotRelational_SeedsRolesAndAdmin()
    {
        using var provider = CreateServices();
        var initializer = CreateInitializer(provider);

        await initializer.InitializeAsync();
        await initializer.InitializeAsync();

        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        Assert.Equal(5, roleManager.Roles.Count());
        Assert.Single(await userManager.GetUsersInRoleAsync(Role.Admin));
    }

    private static IdentityDatabaseInitializer CreateInitializer(ServiceProvider provider) =>
        new(
            provider.GetRequiredService<IdentityDbContext>(),
            provider.GetRequiredService<RoleManager<Role>>(),
            provider.GetRequiredService<UserManager<User>>(),
            Options.Create(ConfiguredSeed),
            Options.Create(new DatabaseInitializationSettings()),
            NullLogger<IdentityDatabaseInitializer>.Instance);

    private static async Task<ServiceProvider> CreateSeededServicesAsync()
    {
        var provider = CreateServices();
        await RoleSeeder.EnsureAsync(provider.GetRequiredService<RoleManager<Role>>());
        return provider;
    }

    private static ServiceProvider CreateServices()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddDbContext<IdentityDbContext>(options =>
            options.UseInMemoryDatabase(Guid.NewGuid().ToString()));
        services.AddIdentityCore<User>()
            .AddRoles<Role>()
            .AddEntityFrameworkStores<IdentityDbContext>();
        return services.BuildServiceProvider();
    }

    private static async Task<User> CreateUserAsync(
        UserManager<User> userManager,
        string email,
        string role)
    {
        var user = User.Create("Test User", email);
        Assert.True((await userManager.CreateAsync(user, "Password123!")).Succeeded);
        Assert.True((await userManager.AddToRoleAsync(user, role)).Succeeded);
        return user;
    }
}
