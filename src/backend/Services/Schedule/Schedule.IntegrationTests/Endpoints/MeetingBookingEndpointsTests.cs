using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Schedule.Application.DTOs;
using Schedule.Domain.Enums;
using Schedule.Infrastructure.Persistence;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class MeetingBookingEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/meetings";
    private static readonly DateTime TenAm = new(2026, 11, 16, 10, 0, 0);

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Create_WhenTeacherIsBusy_Returns409()
    {
        var teacherId = Guid.NewGuid();
        await BookAsync(teacherId, Guid.NewGuid(), null, TenAm, 30);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(10), 30));

        await AssertConflictAsync(response, "teacher");
    }

    [Fact]
    public async Task Create_WhenStudentIsBusy_Returns409()
    {
        var studentId = Guid.NewGuid();
        await BookAsync(Guid.NewGuid(), studentId, null, TenAm, 60);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(Guid.NewGuid(), studentId, null, TenAm.AddMinutes(45), 30));

        await AssertConflictAsync(response, "student");
    }

    [Fact]
    public async Task Create_WhenRoomIsBusy_Returns409()
    {
        var roomId = Guid.NewGuid();
        await BookAsync(Guid.NewGuid(), Guid.NewGuid(), roomId, TenAm, 30);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), roomId, TenAm, 30));

        await AssertConflictAsync(response, "room");
    }

    [Fact]
    public async Task Create_WhenMeetingStartsExactlyWhenAnotherEnds_Returns201()
    {
        var teacherId = Guid.NewGuid();
        await BookAsync(teacherId, Guid.NewGuid(), null, TenAm, 30);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(30), 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task Create_WhenOverlappingMeetingWasCancelled_Returns201()
    {
        var teacherId = Guid.NewGuid();
        var cancelled = await BookAsync(teacherId, Guid.NewGuid(), null, TenAm, 30);
        await CancelAsync(cancelled.Id);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-30)]
    public async Task Create_WhenDurationIsNotPositive_Returns400(int durationMinutes)
    {
        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, durationMinutes));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<MeetingDto> BookAsync(Guid teacherId, Guid studentId, Guid? roomId, DateTime start, int duration)
    {
        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(teacherId, studentId, roomId, start, duration));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }

    private async Task CancelAsync(Guid meetingId)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ScheduleDbContext>();
        var meeting = await db.Meetings.FindAsync(meetingId);
        db.Entry(meeting!).Property(m => m.Status).CurrentValue = MeetingStatus.Cancelled;
        await db.SaveChangesAsync();
    }

    private static async Task AssertConflictAsync(HttpResponseMessage response, string expectedParty)
    {
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Contains(expectedParty, body.GetProperty("message").GetString());
    }
}
