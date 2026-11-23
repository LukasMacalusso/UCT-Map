using Incident.Infrastructure.Persistence;
using MongoDB.Driver;

namespace Incident.IntegrationTests.Fixtures;

/// Base para los tests de persistencia: cada clase de test usa una base de datos
/// propia (nombre único) sobre el mismo contenedor, y la elimina al terminar.

public abstract class MongoTestBase : IAsyncLifetime
{
    private readonly MongoFixture _fixture;
    private readonly string _databaseName;
    private readonly MongoClient _client;

    protected MongoTestBase(MongoFixture fixture)
    {
        _fixture = fixture;
        _databaseName = TestDatabaseNames.New(GetType().Name);
        _client = fixture.CreateClient();
    }

    protected MongoClient Client => _client;

    protected IMongoDbContext CreateContext() => new MongoDbContext(Client, _databaseName);

    public Task InitializeAsync() => Task.CompletedTask;

    public async Task DisposeAsync()
    {
        if (!_fixture.IsAvailable) return;
        await Client.DropDatabaseAsync(_databaseName);
    }
}
