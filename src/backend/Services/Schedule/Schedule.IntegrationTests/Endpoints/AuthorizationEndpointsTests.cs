using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

// Role permissions and cross-user access (IDOR) on the meeting and office hour endpoints.
public class AuthorizationEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string OfficeHours = "/api/schedule/office-hours";
    private const string Meetings = "/api/schedule/meetings";
    private static readonly DateTime TenAm = new(2026, 11, 24, 10, 0, 0);

    private readonly HttpClient _admin = factory.CreateAdminClient();

    [Theory]
    [InlineData(ScheduleApiFactory.StudentRole)]
    [InlineData("ObjectsOfficer")]
    public async Task CreateOfficeHour_WhenRoleIsNotTeacherOrAdmin_Returns403(string role)
    {
        var userId = Guid.NewGuid();

        var response = await factory.CreateClientAs(userId, role).PostAsJsonAsync(OfficeHours, MondayBlock(userId));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateOfficeHour_WhenRequesterIsAStudent_Returns403AndKeepsTheBlock()
    {
        var block = await CreateBlockAsync(Guid.NewGuid());

        var response = await StudentClient(Guid.NewGuid()).PutAsJsonAsync($"{OfficeHours}/{block.Id}",
            new UpdateOfficeHourRequest(null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(12, 0)));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal(block.EndTime, (await GetBlockAsync(block.Id)).EndTime);
    }

    [Fact]
    public async Task DeleteOfficeHour_WhenRequesterIsAStudent_Returns403AndKeepsTheBlock()
    {
        var block = await CreateBlockAsync(Guid.NewGuid());

        var response = await StudentClient(Guid.NewGuid()).DeleteAsync($"{OfficeHours}/{block.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await _admin.GetAsync($"{OfficeHours}/{block.Id}")).StatusCode);
    }

    [Fact]
    public async Task UpdateOfficeHour_WhenRequesterIsAdmin_Returns200()
    {
        var block = await CreateBlockAsync(Guid.NewGuid());

        var response = await _admin.PutAsJsonAsync($"{OfficeHours}/{block.Id}",
            new UpdateOfficeHourRequest(null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(12, 0)));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(new TimeOnly(12, 0), (await GetBlockAsync(block.Id)).EndTime);
    }

    [Fact]
    public async Task DeleteOfficeHour_WhenRequesterIsAdmin_Returns204()
    {
        var block = await CreateBlockAsync(Guid.NewGuid());

        var response = await _admin.DeleteAsync($"{OfficeHours}/{block.Id}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await _admin.GetAsync($"{OfficeHours}/{block.Id}")).StatusCode);
    }

    [Fact]
    public async Task GetMeetingById_WhenRequesterIsTheTeacher_Returns200()
    {
        var meeting = await BookAsync();

        var response = await TeacherClient(meeting.TeacherRefId).GetAsync($"{Meetings}/{meeting.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetMeetingById_WhenRequesterIsAnotherTeacher_Returns403()
    {
        var meeting = await BookAsync();

        var response = await TeacherClient(Guid.NewGuid()).GetAsync($"{Meetings}/{meeting.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetAllMeetings_WhenRequesterIsATeacher_ReturnsOnlyTheirMeetings()
    {
        var mine = await BookAsync();
        await BookAsync();

        var meetings = await TeacherClient(mine.TeacherRefId).GetFromJsonAsync<List<MeetingDto>>(Meetings);

        var meeting = Assert.Single(meetings!);
        Assert.Equal(mine.Id, meeting.Id);
    }

    [Fact]
    public async Task CreateMeeting_WhenTeacherBooksAStudentInTheirOwnHours_Returns201()
    {
        var teacherId = await factory.OpenTeacherDayAsync(TenAm);

        var response = await TeacherClient(teacherId).PostAsJsonAsync(Meetings,
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateMeeting_WhenTeacherBooksForAnotherTeacher_Returns403()
    {
        var otherTeacherId = await factory.OpenTeacherDayAsync(TenAm);

        var response = await TeacherClient(Guid.NewGuid()).PostAsJsonAsync(Meetings,
            new CreateMeetingRequest(otherTeacherId, Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // A student cannot pose as the teacher to book another student: students have no office hours.
    [Fact]
    public async Task CreateMeeting_WhenStudentPosesAsTheTeacher_Returns400()
    {
        var studentId = Guid.NewGuid();

        var response = await StudentClient(studentId).PostAsJsonAsync(Meetings,
            new CreateMeetingRequest(studentId, Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // Only the participants control a meeting's status; administrators included.
    [Theory]
    [InlineData(ScheduleApiFactory.AdminRole, "Cancelled")]
    [InlineData(ScheduleApiFactory.TeacherRole, "Confirmed")]
    public async Task UpdateMeetingStatus_WhenRequesterIsNotAParticipant_Returns403AndKeepsTheMeeting(string role, string status)
    {
        var meeting = await BookAsync();

        var response = await factory.CreateClientAs(Guid.NewGuid(), role).PatchAsJsonAsync(
            $"{Meetings}/{meeting.Id}/status", new UpdateMeetingStatusRequest(status));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("Pending", (await _admin.GetFromJsonAsync<MeetingDto>($"{Meetings}/{meeting.Id}"))!.Status);
    }

    [Theory]
    [InlineData("not-a-guid")]
    [InlineData(null)]
    public async Task CreateMeeting_WhenTokenHasNoValidUserId_Returns401(string? subject)
    {
        List<Claim> claims = [new Claim("role", ScheduleApiFactory.AdminRole)];
        if (subject is not null) claims.Add(new Claim("sub", subject));
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", ScheduleApiFactory.CreateToken(claims));

        var response = await client.PostAsJsonAsync(Meetings,
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private HttpClient StudentClient(Guid userId) => factory.CreateClientAs(userId, ScheduleApiFactory.StudentRole);

    private HttpClient TeacherClient(Guid userId) => factory.CreateClientAs(userId, ScheduleApiFactory.TeacherRole);

    private static CreateOfficeHourRequest MondayBlock(Guid teacherId) =>
        new(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));

    private async Task<OfficeHourDto> CreateBlockAsync(Guid teacherId)
    {
        var response = await TeacherClient(teacherId).PostAsJsonAsync(OfficeHours, MondayBlock(teacherId));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<OfficeHourDto>())!;
    }

    private async Task<OfficeHourDto> GetBlockAsync(Guid id) =>
        (await _admin.GetFromJsonAsync<OfficeHourDto>($"{OfficeHours}/{id}"))!;

    private async Task<MeetingDto> BookAsync()
    {
        var response = await _admin.PostAsJsonAsync(Meetings,
            new CreateMeetingRequest(await factory.OpenTeacherDayAsync(TenAm), Guid.NewGuid(), null, TenAm, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }
}
