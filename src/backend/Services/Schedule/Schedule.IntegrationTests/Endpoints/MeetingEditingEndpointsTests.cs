using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class MeetingEditingEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/meetings";
    private static readonly DateTime TenAm = new(2026, 11, 25, 10, 0, 0);

    private readonly HttpClient _admin = factory.CreateAdminClient();

    [Fact]
    public async Task Reschedule_WhenStudentMovesTheMeeting_Returns200AndPersists()
    {
        var meeting = await BookAsync();
        var roomId = Guid.NewGuid();

        var response = await StudentClient(meeting.StudentRefId).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(roomId, TenAm.AddHours(3), 45));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var stored = await GetAsync(meeting.Id);
        Assert.Equal(TenAm.AddHours(3), stored.ScheduledAt);
        Assert.Equal(45, stored.DurationMinutes);
        Assert.Equal(roomId, stored.StructureRefId);
    }

    [Fact]
    public async Task Reschedule_FreesTheOldSlotForANewMeeting()
    {
        var meeting = await BookAsync();
        await StudentClient(meeting.StudentRefId).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(null, TenAm.AddHours(3), 30));

        var response = await _admin.PostAsJsonAsync(Route,
            new CreateMeetingRequest(meeting.TeacherRefId, Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task Reschedule_WhenTheTeacherIsBusyAtTheNewTime_Returns409()
    {
        var meeting = await BookAsync();
        await BookAsync(meeting.TeacherRefId, TenAm.AddHours(3));

        var response = await StudentClient(meeting.StudentRefId).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(null, TenAm.AddHours(3), 30));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        Assert.Equal(TenAm, (await GetAsync(meeting.Id)).ScheduledAt);
    }

    [Fact]
    public async Task Reschedule_WhenOutsideTheTeachersOfficeHours_Returns400()
    {
        var teacherId = Guid.NewGuid();
        await _admin.PostAsJsonAsync("/api/schedule/office-hours",
            new CreateOfficeHourRequest(teacherId, null, TenAm.DayOfWeek, new TimeOnly(9, 0), new TimeOnly(11, 0)));
        var meeting = await BookAsync(teacherId, TenAm);

        var response = await StudentClient(meeting.StudentRefId).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(null, TenAm.AddHours(4), 30));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Theory]
    [InlineData(ScheduleApiFactory.StudentRole)]
    [InlineData(ScheduleApiFactory.AdminRole)]
    public async Task Reschedule_WhenRequesterIsNotAParticipant_Returns403(string role)
    {
        var meeting = await BookAsync();

        var response = await factory.CreateClientAs(Guid.NewGuid(), role).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(null, TenAm.AddHours(3), 30));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal(TenAm, (await GetAsync(meeting.Id)).ScheduledAt);
    }

    [Fact]
    public async Task Reschedule_WhenMeetingIsCancelled_Returns409()
    {
        var meeting = await BookAsync();
        await StudentClient(meeting.StudentRefId).DeleteAsync($"{Route}/{meeting.Id}");

        var response = await StudentClient(meeting.StudentRefId).PutAsJsonAsync($"{Route}/{meeting.Id}",
            new RescheduleMeetingRequest(null, TenAm.AddHours(3), 30));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Reschedule_WhenMeetingDoesNotExist_Returns404()
    {
        var response = await StudentClient(Guid.NewGuid()).PutAsJsonAsync($"{Route}/{Guid.NewGuid()}",
            new RescheduleMeetingRequest(null, TenAm, 30));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenTheTeacherCancels_Returns204AndKeepsItAsCancelled()
    {
        var meeting = await BookAsync();

        var response = await factory.CreateClientAs(meeting.TeacherRefId, ScheduleApiFactory.TeacherRole)
            .DeleteAsync($"{Route}/{meeting.Id}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal("Cancelled", (await GetAsync(meeting.Id)).Status);
    }

    [Fact]
    public async Task Delete_WhenRequesterIsNotAParticipant_Returns403()
    {
        var meeting = await BookAsync();

        var response = await StudentClient(Guid.NewGuid()).DeleteAsync($"{Route}/{meeting.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("Pending", (await GetAsync(meeting.Id)).Status);
    }

    [Fact]
    public async Task Delete_WhenAlreadyCancelled_Returns409()
    {
        var meeting = await BookAsync();
        await StudentClient(meeting.StudentRefId).DeleteAsync($"{Route}/{meeting.Id}");

        var response = await StudentClient(meeting.StudentRefId).DeleteAsync($"{Route}/{meeting.Id}");

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenMeetingDoesNotExist_Returns404()
    {
        var response = await StudentClient(Guid.NewGuid()).DeleteAsync($"{Route}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task RescheduleAndDelete_WithoutToken_Return401()
    {
        var client = factory.CreateClient();
        var id = Guid.NewGuid();

        var reschedule = await client.PutAsJsonAsync($"{Route}/{id}", new RescheduleMeetingRequest(null, TenAm, 30));
        var delete = await client.DeleteAsync($"{Route}/{id}");

        Assert.Equal(HttpStatusCode.Unauthorized, reschedule.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, delete.StatusCode);
    }

    private HttpClient StudentClient(Guid studentId) => factory.CreateClientAs(studentId, ScheduleApiFactory.StudentRole);

    private async Task<MeetingDto> GetAsync(Guid id) => (await _admin.GetFromJsonAsync<MeetingDto>($"{Route}/{id}"))!;

    private async Task<MeetingDto> BookAsync(Guid? teacherId = null, DateTime? at = null)
    {
        var scheduledAt = at ?? TenAm;
        var teacher = teacherId ?? await factory.OpenTeacherDayAsync(scheduledAt);
        var response = await _admin.PostAsJsonAsync(Route, new CreateMeetingRequest(teacher, Guid.NewGuid(), null, scheduledAt, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }
}
