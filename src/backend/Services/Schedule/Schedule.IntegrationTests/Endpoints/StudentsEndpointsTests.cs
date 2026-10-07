using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class StudentsEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string WeekRange = "from=2026-10-12T00:00:00&to=2026-10-19T00:00:00";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task GetMeetings_ReturnsOnlyThatStudentsMeetingsInRange()
    {
        var studentId = Guid.NewGuid();
        await CreateMeetingAsync(studentId, new DateTime(2026, 10, 13, 10, 0, 0));
        await CreateMeetingAsync(studentId, new DateTime(2026, 10, 27, 10, 0, 0));
        await CreateMeetingAsync(Guid.NewGuid(), new DateTime(2026, 10, 13, 10, 0, 0));

        var result = await _client.GetFromJsonAsync<StudentMeetingsDto>(
            $"/api/schedule/students/{studentId}/meetings?{WeekRange}");

        Assert.NotNull(result);
        Assert.Equal(studentId, result.StudentRefId);
        Assert.Equal(1, result.MeetingCount);
        Assert.Single(result.Meetings);
    }

    [Fact]
    public async Task GetMeetings_WhenToIsNotAfterFrom_Returns400()
    {
        var response = await _client.GetAsync(
            $"/api/schedule/students/{Guid.NewGuid()}/meetings?from=2026-10-19T00:00:00&to=2026-10-12T00:00:00");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetMeetings_WithEmptyStudentId_Returns400()
    {
        var response = await _client.GetAsync($"/api/schedule/students/{Guid.Empty}/meetings?{WeekRange}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task CreateMeetingAsync(Guid studentId, DateTime scheduledAt)
    {
        var response = await _client.PostAsJsonAsync(
            "/api/schedule/meetings", new CreateMeetingRequest(Guid.NewGuid(), studentId, null, scheduledAt, 30));
        response.EnsureSuccessStatusCode();
    }
}
