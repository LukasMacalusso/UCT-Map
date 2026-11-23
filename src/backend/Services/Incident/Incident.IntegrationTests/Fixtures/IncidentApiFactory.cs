using Incident.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using MongoDB.Driver;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Arranca la API real (Program.cs completo: routing, DI, ProblemDetails)
/// apuntando a un MongoDB efímero con una base de datos propia por fábrica.
/// </summary>
public sealed class IncidentApiFactory : WebApplicationFactory<Program>
{
    private readonly MongoFixture _fixture;
    private readonly string _databaseName;
    private readonly MongoClient _client;

    public IncidentApiFactory(MongoFixture fixture)
    {
        _fixture = fixture;
        _databaseName = TestDatabaseNames.New("IncidentApi");
        _client = fixture.CreateClient();
    }

    /// <summary>Cliente apuntando a la base de datos que usa la API en este test.</summary>
    public MongoClient Client => _client;

    public string DatabaseName => _databaseName;

    /// <summary>Contexto de Mongo apuntando a la base de datos que usa la API en este test.</summary>
    public IMongoDbContext CreateContext() => new MongoDbContext(Client, _databaseName);

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Reemplaza los registros de AddInfrastructure por los que apuntan
            // al Mongo efímero, sin tocar la configuración de la aplicación.
            services.RemoveAll<IMongoClient>();
            services.RemoveAll<IMongoDatabase>();
            services.RemoveAll<IMongoDbContext>();

            var client = Client;
            services.AddSingleton<IMongoClient>(client);
            services.AddScoped<IMongoDatabase>(_ => client.GetDatabase(_databaseName));
            services.AddScoped<IMongoDbContext>(_ => new MongoDbContext(client, _databaseName));
        });
    }

    public override async ValueTask DisposeAsync()
    {
        await base.DisposeAsync();
        await DropDatabaseAsync();
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing) DropDatabaseAsync().GetAwaiter().GetResult();
    }

    private async Task DropDatabaseAsync()
    {
        if (!_fixture.IsAvailable) return;
        try
        {
            await Client.DropDatabaseAsync(_databaseName);
        }
        catch
        {
            // El contenedor ya puede haberse reciclado al finalizar los tests.
        }
    }
}
