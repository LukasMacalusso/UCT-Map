using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using Schedule.Application.DTOs;
using Schedule.Domain.Enums;
using Schedule.Infrastructure.Persistence;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class RoomsEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/rooms/availability";
    private const string MondayTenToEleven = "from=2026-11-02T10:00:00&to=2026-11-02T11:00:00";
    private static readonly DateTime MondayTen = new(2026, 11, 2, 10, 0, 0);

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task GetAvailability_CrossesMeetingsAndOfficeHours()
    {
        Guid free = Guid.NewGuid(), withMeeting = Guid.NewGuid(), withOfficeHour = Guid.NewGuid();
        await CreateMeetingAsync(withMeeting, MondayTen.AddMinutes(30));
        await CreateOfficeHourAsync(withOfficeHour, DayOfWeek.Monday);

        var availability = await _client.GetFromJsonAsync<RoomAvailabilityDto>(
            $"{Route}?{MondayTenToEleven}&roomIds={free}&roomIds={withMeeting}&roomIds={withOfficeHour}");

        Assert.NotNull(availability);
        Assert.Equal([free], availability.FreeRoomIds);
        Assert.Contains(availability.Occupancies, o => o.StructureRefId == withMeeting && o.Reason == "Meeting");
        Assert.Contains(availability.Occupancies, o => o.StructureRefId == withOfficeHour && o.Reason == "OfficeHour");
    }

    [Fact]
    public async Task GetAvailability_WhenOfficeHourIsOnAnotherDay_RoomIsFree()
    {
        var room = Guid.NewGuid();
        await CreateOfficeHourAsync(room, DayOfWeek.Friday);

        var availability = await _client.GetFromJsonAsync<RoomAvailabilityDto>($"{Route}?{MondayTenToEleven}&roomIds={room}");

        Assert.Equal([room], availability!.FreeRoomIds);
    }

    [Fact]
    public async Task GetAvailability_WhenOverlappingMeetingWasCancelled_RoomIsFree()
    {
        var room = Guid.NewGuid();
        var meeting = await CreateMeetingAsync(room, MondayTen);
        await CancelAsync(meeting.Id);

        var availability = await _client.GetFromJsonAsync<RoomAvailabilityDto>($"{Route}?{MondayTenToEleven}&roomIds={room}");

        Assert.Equal([room], availability!.FreeRoomIds);
    }

    [Theory]
    [InlineData("roomIds=3fa85f64-5717-4562-b3fc-2c963f66afa6")]
    [InlineData("from=2026-11-02T10:00:00&to=2026-11-02T11:00:00")]
    [InlineData("from=2026-11-02T10:00:00&to=2026-11-03T10:00:00&roomIds=3fa85f64-5717-4562-b3fc-2c963f66afa6")]
    [InlineData("from=2026-11-02T11:00:00&to=2026-11-02T10:00:00&roomIds=3fa85f64-5717-4562-b3fc-2c963f66afa6")]
    public async Task GetAvailability_WithInvalidParameters_Returns400(string query)
    {
        var response = await _client.GetAsync($"{Route}?{query}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<MeetingDto> CreateMeetingAsync(Guid roomId, DateTime start)
    {
        var response = await _client.PostAsJsonAsync("/api/schedule/meetings",
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), roomId, start, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }

    private async Task CreateOfficeHourAsync(Guid roomId, DayOfWeek day)
    {
        var response = await _client.PostAsJsonAsync("/api/schedule/office-hours",
            new CreateOfficeHourRequest(Guid.NewGuid(), roomId, day, new TimeOnly(9, 0), new TimeOnly(12, 0)));
        response.EnsureSuccessStatusCode();
    }

    private async Task CancelAsync(Guid meetingId)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ScheduleDbContext>();
        var meeting = await db.Meetings.FindAsync(meetingId);
        db.Entry(meeting!).Property(m => m.Status).CurrentValue = MeetingStatus.Cancelled;
        await db.SaveChangesAsync();
    }
}
