using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class MeetingsEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/meetings";
    private const string WeekRange = "from=2026-10-12T00:00:00&to=2026-10-19T00:00:00";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Create_WithValidRequest_Returns201InPendingStatus()
    {
        var request = new CreateMeetingRequest(
            Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), new DateTime(2026, 10, 13, 10, 0, 0), 30);

        var response = await _client.PostAsJsonAsync(Route, request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<MeetingDto>();
        Assert.Equal("Pending", created?.Status);
        Assert.Equal(30, created?.DurationMinutes);
    }

    [Fact]
    public async Task GetById_WhenMeetingExists_Returns200()
    {
        var created = await CreateAsync(Guid.NewGuid(), new DateTime(2026, 10, 13, 10, 0, 0));

        var response = await _client.GetAsync($"{Route}/{created.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetById_WhenMeetingDoesNotExist_Returns404()
    {
        var response = await _client.GetAsync($"{Route}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetByTeacher_ReturnsOnlyMeetingsInsideRange()
    {
        var teacherId = Guid.NewGuid();
        await CreateAsync(teacherId, new DateTime(2026, 10, 13, 10, 0, 0));
        await CreateAsync(teacherId, new DateTime(2026, 10, 30, 10, 0, 0));

        var meetings = await _client.GetFromJsonAsync<List<MeetingDto>>($"{Route}?teacherId={teacherId}&{WeekRange}");

        Assert.NotNull(meetings);
        Assert.Single(meetings);
    }

    [Fact]
    public async Task GetByTeacher_WhenToIsNotAfterFrom_Returns400()
    {
        var response = await _client.GetAsync(
            $"{Route}?teacherId={Guid.NewGuid()}&from=2026-10-19T00:00:00&to=2026-10-12T00:00:00");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetAll_WithoutTeacherId_ReturnsEveryMeeting()
    {
        var first = await CreateAsync(Guid.NewGuid(), new DateTime(2026, 11, 2, 9, 0, 0));
        var second = await CreateAsync(Guid.NewGuid(), new DateTime(2026, 11, 20, 9, 0, 0));

        var meetings = await _client.GetFromJsonAsync<List<MeetingDto>>(Route);

        Assert.NotNull(meetings);
        Assert.Contains(meetings, m => m.Id == first.Id);
        Assert.Contains(meetings, m => m.Id == second.Id);
    }

    [Fact]
    public async Task Get_WithEmptyTeacherId_Returns400()
    {
        var response = await _client.GetAsync($"{Route}?teacherId={Guid.Empty}&{WeekRange}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetByTeacher_WithoutDateRange_Returns400()
    {
        var response = await _client.GetAsync($"{Route}?teacherId={Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<MeetingDto> CreateAsync(Guid teacherId, DateTime scheduledAt)
    {
        var request = new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, scheduledAt, 30);
        var response = await _client.PostAsJsonAsync(Route, request);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }
}
