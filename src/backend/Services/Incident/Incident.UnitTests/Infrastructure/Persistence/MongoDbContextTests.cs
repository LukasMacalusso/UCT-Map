using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence;
using MongoDB.Driver;

namespace Incident.UnitTests.Infrastructure.Persistence;

/// <summary>
/// Verifica que el contexto de Mongo exponga la base configurada y las
/// colecciones por nombre. Construir el cliente no abre conexión, así que no
/// necesita un servidor Mongo.
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

    [Fact]
    public void GetCollection_DevuelveUnaColeccionDelTipoSolicitado()
    {
        var context = CreateContext();

        var collection = context.GetCollection<Ticket>("tickets");

        Assert.Equal("tickets", collection.CollectionNamespace.CollectionName);
    }
}
