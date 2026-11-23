using Incident.API.Controllers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Driver;
using NSubstitute;

namespace Incident.UnitTests.API.Controllers;

/// <summary>
/// Cubre el health check y, en especial, la rama de error cuando Mongo no
/// responde (503) que no se puede provocar con un contenedor sano.
/// </summary>
public class HealthControllerTests
{
    private static object? ReadProperty(object value, string name) =>
        value.GetType().GetProperty(name)?.GetValue(value);

    [Fact]
    public void Get_Retorna200ConElServicioSano()
    {
        var result = new HealthController().Get();

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(StatusCodes.Status200OK, ok.StatusCode);
        Assert.Equal("incident-service", ReadProperty(ok.Value!, "service"));
        Assert.Equal("healthy", ReadProperty(ok.Value!, "status"));
    }

    [Fact]
    public async Task Ready_CuandoMongoResponde_Retorna200ConLaBaseConectada()
    {
        var database = Substitute.For<IMongoDatabase>();
        database
            .RunCommandAsync<BsonDocument>(
                Arg.Any<Command<BsonDocument>>(),
                Arg.Any<ReadPreference>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(new BsonDocument("ok", 1)));

        var mongo = Substitute.For<IMongoClient>();
        mongo.GetDatabase("admin").Returns(database);

        var result = await new HealthController().Ready(mongo);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("ready", ReadProperty(ok.Value!, "status"));
        Assert.Equal("connected", ReadProperty(ok.Value!, "database"));
    }

    [Fact]
    public async Task Ready_CuandoMongoFalla_Retorna503ConLaBaseDesconectada()
    {
        var mongo = Substitute.For<IMongoClient>();
        mongo.GetDatabase("admin").Returns(_ => throw new MongoException("sin conexión"));

        var result = await new HealthController().Ready(mongo);

        var error = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status503ServiceUnavailable, error.StatusCode);
        Assert.Equal("unhealthy", ReadProperty(error.Value!, "status"));
        Assert.Equal("disconnected", ReadProperty(error.Value!, "database"));
    }
}
