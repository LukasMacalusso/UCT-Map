using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

// A user can only reach their own schedule data unless they are an administrator (IDOR protection).
public class OwnershipEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Range = "from=2026-11-16T00:00:00&to=2026-11-23T00:00:00";
    private static readonly DateTime TenAm = new(2026, 11, 17, 10, 0, 0);

    [Fact]
    public async Task GetStudentMeetings_WhenRequesterIsTheStudent_Returns200()
    {
        var studentId = Guid.NewGuid();

        var response = await StudentClient(studentId).GetAsync($"/api/schedule/students/{studentId}/meetings?{Range}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetStudentMeetings_WhenRequesterIsAnotherStudent_Returns403()
    {
        var response = await StudentClient(Guid.NewGuid()).GetAsync($"/api/schedule/students/{Guid.NewGuid()}/meetings?{Range}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetTeacherWorkload_WhenRequesterIsTheTeacher_Returns200()
    {
        var teacherId = Guid.NewGuid();

        var response = await TeacherClient(teacherId).GetAsync($"/api/schedule/teachers/{teacherId}/workload?{Range}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetTeacherWorkload_WhenRequesterIsAnotherUser_Returns403()
    {
        var response = await StudentClient(Guid.NewGuid()).GetAsync($"/api/schedule/teachers/{Guid.NewGuid()}/workload?{Range}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetTeacherWorkload_WhenRequesterIsAdmin_Returns200()
    {
        var response = await factory.CreateAdminClient().GetAsync($"/api/schedule/teachers/{Guid.NewGuid()}/workload?{Range}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetMeetingById_WhenRequesterIsAParticipant_Returns200()
    {
        var meeting = await BookAsync();

        var response = await StudentClient(meeting.StudentRefId).GetAsync($"/api/schedule/meetings/{meeting.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetMeetingById_WhenRequesterIsNotAParticipant_Returns403()
    {
        var meeting = await BookAsync();

        var response = await StudentClient(Guid.NewGuid()).GetAsync($"/api/schedule/meetings/{meeting.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GetAllMeetings_WhenRequesterIsNotAdmin_ReturnsOnlyTheirMeetings()
    {
        var mine = await BookAsync();
        await BookAsync();

        var meetings = await StudentClient(mine.StudentRefId).GetFromJsonAsync<List<MeetingDto>>("/api/schedule/meetings");

        var meeting = Assert.Single(meetings!);
        Assert.Equal(mine.Id, meeting.Id);
    }

    [Fact]
    public async Task CreateMeeting_WhenStudentBooksForThemselves_Returns201()
    {
        var studentId = Guid.NewGuid();

        var response = await StudentClient(studentId).PostAsJsonAsync("/api/schedule/meetings",
            new CreateMeetingRequest(Guid.NewGuid(), studentId, null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateMeeting_OnBehalfOfAnotherStudent_Returns403()
    {
        var response = await StudentClient(Guid.NewGuid()).PostAsJsonAsync("/api/schedule/meetings",
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CreateOfficeHour_WhenTeacherCreatesTheirOwn_Returns201()
    {
        var teacherId = Guid.NewGuid();

        var response = await TeacherClient(teacherId).PostAsJsonAsync("/api/schedule/office-hours",
            new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateOfficeHour_ForAnotherTeacher_Returns403()
    {
        var response = await TeacherClient(Guid.NewGuid()).PostAsJsonAsync("/api/schedule/office-hours",
            new CreateOfficeHourRequest(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Theory]
    [InlineData("/api/schedule/teachers/{0}/availability")]
    [InlineData("/api/schedule/meetings?teacherId={0}&" + Range)]
    [InlineData("/api/schedule/office-hours?teacherId={0}")]
    public async Task PublicScheduleData_WhenRequesterIsAnyUser_Returns200(string routeTemplate)
    {
        var response = await StudentClient(Guid.NewGuid()).GetAsync(string.Format(routeTemplate, Guid.NewGuid()));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private HttpClient StudentClient(Guid userId) => factory.CreateClientAs(userId, ScheduleApiFactory.StudentRole);

    private HttpClient TeacherClient(Guid userId) => factory.CreateClientAs(userId, ScheduleApiFactory.TeacherRole);

    private async Task<MeetingDto> BookAsync()
    {
        var response = await factory.CreateAdminClient().PostAsJsonAsync("/api/schedule/meetings",
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }
}
