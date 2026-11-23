using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence;
using MongoDB.Driver;

namespace Incident.IntegrationTests.Persistence;

/// <summary>
/// Verifica que el contexto de Mongo exponga la base configurada y las
/// colecciones por nombre. No necesita un servidor Mongo para construirse.
/// </summary>
public class MongoDbContextTests
{
    private const string DatabaseName = "incident_test_db";

    private static MongoDbContext CreateContext() =>
        new(new MongoClient("mongodb://localhost:27017"), DatabaseName);

    [Fact]
    public void Database_ExponeLaBaseConfigurada()
    {
        var context = CreateContext();

        Assert.Equal(DatabaseName, context.Database.DatabaseNamespace.DatabaseName);
    }

    [Fact]
    public void GetCollection_UsaElNombreIndicado()
    {
        var context = CreateContext();

        var collection = context.GetCollection<LostObject>("lost_objects");

        Assert.Equal("lost_objects", collection.CollectionNamespace.CollectionName);
    }
}
