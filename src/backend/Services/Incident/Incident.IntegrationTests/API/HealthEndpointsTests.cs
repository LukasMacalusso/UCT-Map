using Incident.IntegrationTests.Fixtures;
using System.Net;

namespace Incident.IntegrationTests.API;

[Collection(MongoCollection.Name)]
public class HealthEndpointsTests : ApiTestBase
{
    public HealthEndpointsTests(MongoFixture fixture) : base(fixture) { }

    private sealed record HealthResponse(string Service, string Status);
    private sealed record ReadyResponse(string Service, string Status, string Database);

    [DockerFact]
    public async Task GetHealth_Retorna200ConElServicioSano()
    {
        var response = await Http.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await ReadJsonAsync<HealthResponse>(response);
        Assert.Equal("incident-service", body!.Service);
        Assert.Equal("healthy", body.Status);
    }

    [DockerFact]
    public async Task GetHealthReady_Retorna200ConLaBaseConectada()
    {
        var response = await Http.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await ReadJsonAsync<ReadyResponse>(response);
        Assert.Equal("incident-service", body!.Service);
        Assert.Equal("ready", body.Status);
        Assert.Equal("connected", body.Database);
    }
}
