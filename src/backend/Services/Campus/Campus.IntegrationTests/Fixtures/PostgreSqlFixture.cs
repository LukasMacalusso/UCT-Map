using System;
using System.Threading.Tasks;
using Testcontainers.PostgreSql;
using Xunit;

namespace Campus.IntegrationTests.Fixtures;

/// <summary>
/// Levanta un PostgreSQL efímero con Testcontainers y lo mantiene
/// durante toda la colección de tests de integración.
/// </summary>
public sealed class PostgreSqlFixture : IAsyncLifetime
{
    private PostgreSqlContainer? _container;

    public string ConnectionString { get; private set; } = string.Empty;
    public bool IsAvailable { get; private set; }

    public async Task InitializeAsync()
    {
        if (!DockerCheck.IsAvailable.Value) return;

        try
        {
            _container = new PostgreSqlBuilder("postgres:16-alpine")
                .WithDatabase("campus_integration_test")
                .WithUsername("postgres")
                .WithPassword("postgres")
                .Build();

            await _container.StartAsync();
            ConnectionString = _container.GetConnectionString();
            IsAvailable = true;
        }
        catch (Exception)
        {
            IsAvailable = false;
        }
    }

    public async Task DisposeAsync()
    {
        if (_container is not null)
            await _container.DisposeAsync();
    }
}

[CollectionDefinition(Name)]
public sealed class PostgreSqlCollection : ICollectionFixture<PostgreSqlFixture>
{
    public const string Name = "PostgreSQL efímero (Testcontainers)";
}
