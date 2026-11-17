using System.Net;
using System.Net.Http.Headers;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class AuthenticationEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Range = "from=2026-11-16T00:00:00&to=2026-11-17T00:00:00";

    public static TheoryData<string> ProtectedRoutes => new()
    {
        "/api/schedule/office-hours",
        "/api/schedule/meetings",
        $"/api/schedule/teachers/{Guid.NewGuid()}/workload?{Range}",
        $"/api/schedule/teachers/{Guid.NewGuid()}/availability",
        $"/api/schedule/students/{Guid.NewGuid()}/meetings?{Range}",
        $"/api/schedule/rooms/availability?roomIds={Guid.NewGuid()}&{Range}"
    };

    [Theory]
    [MemberData(nameof(ProtectedRoutes))]
    public async Task Get_WithoutToken_Returns401(string route)
    {
        var response = await factory.CreateClient().GetAsync(route);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Theory]
    [MemberData(nameof(ProtectedRoutes))]
    public async Task Get_WithTokenSignedByAnotherKey_Returns401(string route)
    {
        var client = factory.CreateClient();
        var forgedToken = ScheduleApiFactory.CreateToken(
            Guid.NewGuid(), ScheduleApiFactory.AdminRole, "forged-signing-key-0123456789abcdefghij");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", forgedToken);

        var response = await client.GetAsync(route);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Health_WithoutToken_Returns200()
    {
        var response = await factory.CreateClient().GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
