using Identity.Domain.Entities;
using Identity.Infrastructure;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Testcontainers.PostgreSql;

namespace Identity.IntegrationTests;

public sealed class PostgresContainerFixture : IAsyncLifetime
{
    private PostgreSqlContainer? _container;

    public bool IsAvailable { get; private set; }

    public string CreateConnectionString(string database) =>
        new NpgsqlConnectionStringBuilder(_container!.GetConnectionString()) { Database = database }.ConnectionString;

    public async Task InitializeAsync()
    {
        try
        {
            _container = new PostgreSqlBuilder("postgres:17-alpine").Build();
            await _container.StartAsync();
            IsAvailable = true;
        }
        catch (Exception) when (!IsRunningInCi())
        {
            IsAvailable = false;
        }
    }

    public async Task DisposeAsync()
    {
        if (_container is not null)
        {
            await _container.DisposeAsync();
        }
    }

    private static bool IsRunningInCi() =>
        string.Equals(Environment.GetEnvironmentVariable("CI"), "true", StringComparison.OrdinalIgnoreCase);
}

public sealed class IdentityDatabaseInitializerPostgresTests(PostgresContainerFixture postgres)
    : IClassFixture<PostgresContainerFixture>
{
    private const string AdminEmail = "admin@uct.cl";
    private const string AdminPassword = "Seed-Admin-Password1!";

    [Fact]
    public async Task InitializeAsync_WhenInstancesRunConcurrently_MigratesAndSeedsOnce()
    {
        if (!postgres.IsAvailable) return;

        using var provider = CreateServices(UniqueDatabase());

        await Task.WhenAll(
            InitializeAsync(provider),
            InitializeAsync(provider),
            InitializeAsync(provider));

        await using var scope = provider.CreateAsyncScope();
        var context = scope.ServiceProvider.GetRequiredService<IdentityDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();

        Assert.Empty(await context.Database.GetPendingMigrationsAsync());
        Assert.Equal(
            context.Database.GetMigrations().Count(),
            (await context.Database.GetAppliedMigrationsAsync()).Count());
        Assert.Equal(5, await context.Roles.CountAsync());

        var admin = Assert.Single(await userManager.GetUsersInRoleAsync(Role.Admin));
        Assert.Equal(AdminEmail, admin.Email);
        Assert.Equal(1, await context.Users.CountAsync());
    }

    [Fact]
    public async Task InitializeAsync_WhenRunAgain_IsIdempotent()
    {
        if (!postgres.IsAvailable) return;

        using var provider = CreateServices(UniqueDatabase());

        await InitializeAsync(provider);
        await InitializeAsync(provider);

        await using var scope = provider.CreateAsyncScope();
        var context = scope.ServiceProvider.GetRequiredService<IdentityDbContext>();
        Assert.Equal(5, await context.Roles.CountAsync());
        Assert.Equal(1, await context.Users.CountAsync());
    }

    [Fact]
    public async Task InitializeAsync_WhenLockIsHeldTooLong_ThrowsTimeout()
    {
        if (!postgres.IsAvailable) return;

        var database = UniqueDatabase();
        using var provider = CreateServices(database, lockTimeoutSeconds: 1);
        await InitializeAsync(provider);

        await using var lockHolder = new NpgsqlConnection(postgres.CreateConnectionString(database));
        await lockHolder.OpenAsync();
        await using (var command = new NpgsqlCommand("SELECT pg_advisory_lock(7139001)", lockHolder))
        {
            await command.ExecuteScalarAsync();
        }

        await Assert.ThrowsAsync<TimeoutException>(() => InitializeAsync(provider));
    }

    private static async Task InitializeAsync(ServiceProvider provider)
    {
        await using var scope = provider.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IdentityDatabaseInitializer>().InitializeAsync();
    }

    private ServiceProvider CreateServices(string database, int lockTimeoutSeconds = 60)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:IdentityDb"] = postgres.CreateConnectionString(database),
                ["IdentitySeed:AdminEmail"] = AdminEmail,
                ["IdentitySeed:AdminPassword"] = AdminPassword,
                ["Database:MigrationLockTimeoutSeconds"] = lockTimeoutSeconds.ToString()
            })
            .Build();

        var services = new ServiceCollection();
        services.AddLogging();
        services.AddInfrastructure(configuration);
        return services.BuildServiceProvider();
    }

    private static string UniqueDatabase() => $"identity_init_{Guid.NewGuid():N}";
}
