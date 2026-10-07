using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class TeachersEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string WeekRange = "from=2026-10-12T00:00:00&to=2026-10-19T00:00:00";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task GetWorkload_SumsOfficeHoursAndCountsMeetingsInRange()
    {
        var teacherId = Guid.NewGuid();
        await CreateOfficeHourAsync(teacherId, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0));
        await CreateOfficeHourAsync(teacherId, DayOfWeek.Wednesday, new TimeOnly(15, 0), new TimeOnly(16, 0));
        await CreateMeetingAsync(teacherId, new DateTime(2026, 10, 12, 9, 30, 0));
        await CreateMeetingAsync(teacherId, new DateTime(2026, 10, 26, 9, 30, 0));

        var workload = await _client.GetFromJsonAsync<TeacherWorkloadDto>(
            $"/api/schedule/teachers/{teacherId}/workload?{WeekRange}");

        Assert.NotNull(workload);
        Assert.Equal(180, workload.WeeklyOfficeHourMinutes);
        Assert.Equal(1, workload.MeetingCount);
        Assert.Equal(2, workload.OfficeHours.Count);
    }

    [Fact]
    public async Task GetWorkload_WhenToIsNotAfterFrom_Returns400()
    {
        var response = await _client.GetAsync(
            $"/api/schedule/teachers/{Guid.NewGuid()}/workload?from=2026-10-19T00:00:00&to=2026-10-12T00:00:00");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetWorkload_WithEmptyTeacherId_Returns400()
    {
        var response = await _client.GetAsync($"/api/schedule/teachers/{Guid.Empty}/workload?{WeekRange}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetAvailability_ReturnsTeachersOfficeHourBlocks()
    {
        var teacherId = Guid.NewGuid();
        await CreateOfficeHourAsync(teacherId, DayOfWeek.Friday, new TimeOnly(10, 0), new TimeOnly(12, 0));

        var availability = await _client.GetFromJsonAsync<TeacherAvailabilityDto>(
            $"/api/schedule/teachers/{teacherId}/availability");

        Assert.NotNull(availability);
        Assert.Equal(teacherId, availability.TeacherRefId);
        Assert.Single(availability.AvailableBlocks);
        Assert.Equal("Friday", availability.AvailableBlocks[0].DayOfWeek);
    }

    [Fact]
    public async Task GetAvailability_WithEmptyTeacherId_Returns400()
    {
        var response = await _client.GetAsync($"/api/schedule/teachers/{Guid.Empty}/availability");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task CreateOfficeHourAsync(Guid teacherId, DayOfWeek day, TimeOnly start, TimeOnly end)
    {
        var response = await _client.PostAsJsonAsync(
            "/api/schedule/office-hours", new CreateOfficeHourRequest(teacherId, null, day, start, end));
        response.EnsureSuccessStatusCode();
    }

    private async Task CreateMeetingAsync(Guid teacherId, DateTime scheduledAt)
    {
        var response = await _client.PostAsJsonAsync(
            "/api/schedule/meetings", new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, scheduledAt, 30));
        response.EnsureSuccessStatusCode();
    }
}
