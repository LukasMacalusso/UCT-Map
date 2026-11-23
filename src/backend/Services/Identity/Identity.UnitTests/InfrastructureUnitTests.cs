using ErrorOr;
using Identity.Application.DTOs;
using Identity.Application.Handlers;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Identity.Infrastructure;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Identity;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Identity.UnitTests;

public sealed class InfrastructureUnitTests
{
    private const string Password = "Password123!";

    [Fact]
    public async Task RoleSeeder_CreatesDefaultRolesOnce()
    {
        using var provider = CreateServices();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();

        await RoleSeeder.EnsureAsync(roleManager);
        await RoleSeeder.EnsureAsync(roleManager);

        Assert.Equal(5, roleManager.Roles.Count());
        Assert.True(await roleManager.RoleExistsAsync(Role.ComplaintsOfficer));
    }

    [Fact]
    public async Task RoleSeeder_WhenRoleManagerIsNull_Throws()
    {
        await Assert.ThrowsAsync<ArgumentNullException>(() => RoleSeeder.EnsureAsync(null!));
    }

    [Fact]
    public void AddInfrastructure_RegistersApplicationServices()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:IdentityDb"] = "Host=localhost;Database=identity"
            })
            .Build();
        var services = new ServiceCollection();
        services.AddLogging();

        services.AddInfrastructure(configuration);
        using var provider = services.BuildServiceProvider();
        using var scope = provider.CreateScope();

        Assert.IsType<IdentityRoleManagementService>(
            scope.ServiceProvider.GetRequiredService<IRoleManagementService>());
        Assert.NotNull(scope.ServiceProvider.GetRequiredService<RoleManagementHandler>());
        Assert.NotNull(scope.ServiceProvider.GetRequiredService<IdentityDbContext>().Model);
    }

    [Fact]
    public void AddInfrastructure_WhenConnectionStringIsMissing_Throws()
    {
        var configuration = new ConfigurationBuilder().Build();

        Assert.Throws<InvalidOperationException>(() =>
            new ServiceCollection().AddInfrastructure(configuration));
    }

    [Fact]
    public async Task IdentityUserQuery_ReturnsUsersWithRoles()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        await provider.GetRequiredService<RoleManager<Role>>().CreateAsync(new Role(Role.Teacher));
        var user = await CreateUserAsync(userManager, "teacher@uct.cl");
        await userManager.AddToRoleAsync(user, Role.Teacher);
        var query = new IdentityUserQuery(userManager);

        var all = await query.GetAllAsync();
        var found = await query.GetByIdAsync(user.Id);

        Assert.Equal(Role.Teacher, Assert.Single(all).Role);
        Assert.Equal("teacher@uct.cl", found?.Email);
        Assert.Null(await query.GetByIdAsync(""));
        Assert.Null(await query.GetByIdAsync("missing-user"));
    }

    [Fact]
    public async Task RegisterAsync_WhenRequestIsInvalidOrDuplicated_ReturnsNull()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        await CreateUserAsync(userManager, "taken@uct.cl");
        var service = new IdentityUserRegistrationService(
            userManager,
            provider.GetRequiredService<RoleManager<Role>>());

        Assert.Null(await service.RegisterAsync(new RegisterRequest("", "new@uct.cl", Password)));
        Assert.Null(await service.RegisterAsync(new RegisterRequest("User", "taken@uct.cl", Password)));
        Assert.Null(await service.RegisterAsync(new RegisterRequest("User", "weak@uct.cl", "weak")));
    }

    [Fact]
    public async Task RoleManagementService_WhenUserDoesNotExist_ReturnsNotFound()
    {
        using var provider = CreateServices();
        var service = CreateRoleService(provider);

        var results = new[]
        {
            (await service.GetRolesAsync("missing")).FirstError.Type,
            (await service.AddRoleAsync("missing", Role.Teacher)).FirstError.Type,
            (await service.ReplaceRolesAsync("", [Role.Teacher])).FirstError.Type,
            (await service.RemoveRoleAsync("missing", Role.Teacher)).FirstError.Type,
            (await service.SetSuspendedAsync("missing", true)).FirstError.Type
        };

        Assert.All(results, type => Assert.Equal(ErrorType.NotFound, type));
    }

    [Fact]
    public async Task RoleManagementService_ManagesRolesForExistingUser()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        await roleManager.CreateAsync(new Role(Role.Teacher));
        var user = await CreateUserAsync(userManager, "user@uct.cl");
        var service = CreateRoleService(provider);

        Assert.Empty((await service.GetRolesAsync(user.Id)).Value.Roles);
        Assert.Equal(ErrorType.Validation, (await service.AddRoleAsync(user.Id, " ")).FirstError.Type);
        Assert.Equal(ErrorType.NotFound, (await service.AddRoleAsync(user.Id, "Unknown")).FirstError.Type);
        Assert.False((await service.AddRoleAsync(user.Id, Role.Teacher)).IsError);
        Assert.Equal(ErrorType.Conflict, (await service.AddRoleAsync(user.Id, Role.Teacher)).FirstError.Type);
        Assert.Equal(ErrorType.NotFound, (await service.ReplaceRolesAsync(user.Id, ["Unknown"])).FirstError.Type);
        Assert.False((await service.RemoveRoleAsync(user.Id, Role.Teacher)).IsError);
        Assert.Equal(ErrorType.NotFound, (await service.RemoveRoleAsync(user.Id, Role.Teacher)).FirstError.Type);
        Assert.Empty((await service.ReplaceRolesAsync(user.Id, [])).Value.Roles);
    }

    private static IdentityRoleManagementService CreateRoleService(ServiceProvider provider) =>
        new(
            provider.GetRequiredService<UserManager<User>>(),
            provider.GetRequiredService<RoleManager<Role>>());

    private static ServiceProvider CreateServices()
    {
        var services = new ServiceCollection();
        services.AddDbContext<IdentityDbContext>(options =>
            options.UseInMemoryDatabase(Guid.NewGuid().ToString()));
        services.AddIdentityCore<User>()
            .AddRoles<Role>()
            .AddEntityFrameworkStores<IdentityDbContext>();
        return services.BuildServiceProvider();
    }

    private static async Task<User> CreateUserAsync(UserManager<User> userManager, string email)
    {
        var user = User.Create("Test User", email);
        var result = await userManager.CreateAsync(user, Password);
        Assert.True(result.Succeeded);
        return user;
    }
}
