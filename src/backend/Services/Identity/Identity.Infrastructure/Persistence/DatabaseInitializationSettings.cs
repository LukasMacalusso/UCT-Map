namespace Identity.Infrastructure.Persistence;

public sealed class DatabaseInitializationSettings
{
    public const string SectionName = "Database";

    public bool ApplyMigrationsOnStartup { get; init; } = true;

    public int MigrationLockTimeoutSeconds { get; init; } = 120;
}
