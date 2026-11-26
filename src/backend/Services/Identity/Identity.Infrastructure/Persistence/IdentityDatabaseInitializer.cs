using Identity.Domain.Entities;
using Identity.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;

namespace Identity.Infrastructure.Persistence;

public sealed class IdentityDatabaseInitializer(
    IdentityDbContext context,
    RoleManager<Role> roleManager,
    UserManager<User> userManager,
    IOptions<IdentitySeedSettings> seedOptions,
    IOptions<DatabaseInitializationSettings> databaseOptions,
    ILogger<IdentityDatabaseInitializer> logger)
{
    private const long InitializationLockKey = 7_139_001;
    private static readonly TimeSpan LockRetryDelay = TimeSpan.FromSeconds(2);

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        if (!context.Database.IsRelational())
        {
            await SeedAsync();
            return;
        }

        await EnsureDatabaseExistsAsync(cancellationToken);

        var lockAcquired = false;
        await context.Database.OpenConnectionAsync(cancellationToken);
        try
        {
            if (context.Database.IsNpgsql())
            {
                await AcquireLockAsync(cancellationToken);
                lockAcquired = true;
            }

            var pendingMigrations = (await context.Database.GetPendingMigrationsAsync(cancellationToken)).ToArray();
            if (pendingMigrations.Length > 0)
            {
                logger.LogInformation(
                    "Applying {Count} Identity migration(s): {Migrations}",
                    pendingMigrations.Length,
                    string.Join(", ", pendingMigrations));
                await context.Database.MigrateAsync(cancellationToken);
            }
            else
            {
                logger.LogInformation("Identity database is up to date. No migrations to apply.");
            }

            await SeedAsync();
        }
        finally
        {
            if (lockAcquired) await ReleaseLockAsync();
            await context.Database.CloseConnectionAsync();
        }
    }

    private async Task EnsureDatabaseExistsAsync(CancellationToken cancellationToken)
    {
        var databaseCreator = context.GetService<IRelationalDatabaseCreator>();
        if (await databaseCreator.ExistsAsync(cancellationToken)) return;

        try
        {
            logger.LogInformation("Identity database does not exist. Creating it.");
            await databaseCreator.CreateAsync(cancellationToken);
        }
        catch (PostgresException exception) when (exception.SqlState == PostgresErrorCodes.DuplicateDatabase)
        {
            logger.LogInformation("Identity database was created by another instance.");
        }
    }

    private async Task SeedAsync()
    {
        await RoleSeeder.EnsureAsync(roleManager);
        await RoleSeeder.EnsureAdminAsync(userManager, seedOptions.Value, logger);
    }

    private async Task AcquireLockAsync(CancellationToken cancellationToken)
    {
        var timeout = TimeSpan.FromSeconds(Math.Max(1, databaseOptions.Value.MigrationLockTimeoutSeconds));
        var deadline = DateTime.UtcNow + timeout;

        while (true)
        {
            var acquired = await context.Database
                .SqlQuery<bool>($"SELECT pg_try_advisory_lock({InitializationLockKey}) AS \"Value\"")
                .SingleAsync(cancellationToken);

            if (acquired) return;

            if (DateTime.UtcNow >= deadline)
            {
                throw new TimeoutException(
                    $"Another instance kept the Identity migration lock for more than {timeout.TotalSeconds} seconds.");
            }

            logger.LogInformation("Waiting for another instance to finish the Identity migrations...");
            await Task.Delay(LockRetryDelay, cancellationToken);
        }
    }

    private async Task ReleaseLockAsync()
    {
        await context.Database
            .SqlQuery<bool>($"SELECT pg_advisory_unlock({InitializationLockKey}) AS \"Value\"")
            .SingleAsync();
    }
}
