using MongoDB.Driver;
using Testcontainers.MongoDb;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Levanta un MongoDB efímero (misma versión que docker-compose) con
/// Testcontainers y lo mantiene durante toda la colección de tests.
/// </summary>
public sealed class MongoFixture : IAsyncLifetime
{
    private MongoDbContainer? _container;

    /// <summary>Connection string del contenedor efímero.</summary>
    public string ConnectionString { get; private set; } = "mongodb://localhost:27017";

    public bool IsAvailable { get; private set; }

    public async Task InitializeAsync()
    {
        if (!DockerCheck.IsAvailable.Value) return;

        try
        {
            _container = new MongoDbBuilder("mongo:6-jammy")
                .Build();

            await _container.StartAsync();
            ConnectionString = _container.GetConnectionString();
            IsAvailable = true;
        }
        catch (Exception)
        {
            // Sin daemon de Docker: los tests quedan igual omitidos por [DockerFact].
            IsAvailable = false;
        }
    }

    public async Task DisposeAsync()
    {
        if (_container is not null)
            await _container.DisposeAsync();
    }

    /// <summary>Crea un cliente apuntando al Mongo efímero.</summary>
    public MongoClient CreateClient() => new(ConnectionString);
}

[CollectionDefinition(Name)]
public sealed class MongoCollection : ICollectionFixture<MongoFixture>
{
    public const string Name = "Mongo efímero (Testcontainers)";
}
