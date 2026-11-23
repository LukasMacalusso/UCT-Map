using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class HealthEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task GetHealth_ReturnsHealthyService()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("schedule-service", body.GetProperty("service").GetString());
        Assert.Equal("healthy", body.GetProperty("status").GetString());
    }

    [Fact]
    public async Task GetDatabaseHealth_WhenDatabaseIsReachable_ReturnsConnected()
    {
        var response = await _client.GetAsync("/health/database");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("connected", body.GetProperty("status").GetString());
    }
}
