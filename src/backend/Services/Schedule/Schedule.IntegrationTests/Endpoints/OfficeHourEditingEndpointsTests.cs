using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class OfficeHourEditingEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/office-hours";

    // A Monday far enough ahead to always be an upcoming meeting.
    private static readonly DateTime UpcomingMonday = new(2030, 1, 7);

    private readonly HttpClient _admin = factory.CreateAdminClient();

    [Fact]
    public async Task Update_WhenTeacherEditsTheirBlock_Returns200()
    {
        var teacherId = Guid.NewGuid();
        var block = await CreateBlockAsync(teacherId, 9, 10);

        var response = await TeacherClient(teacherId).PutAsJsonAsync($"{Route}/{block.Id}", MondayRequest(9, 12));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var stored = await _admin.GetFromJsonAsync<OfficeHourDto>($"{Route}/{block.Id}");
        Assert.Equal(new TimeOnly(12, 0), stored!.EndTime);
    }

    [Fact]
    public async Task Update_WhenRequesterIsAnotherTeacher_Returns403()
    {
        var block = await CreateBlockAsync(Guid.NewGuid(), 9, 10);

        var response = await TeacherClient(Guid.NewGuid()).PutAsJsonAsync($"{Route}/{block.Id}", MondayRequest(9, 12));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Update_WhenBlockDoesNotExist_Returns404()
    {
        var response = await _admin.PutAsJsonAsync($"{Route}/{Guid.NewGuid()}", MondayRequest(9, 12));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Update_WhenEndIsNotAfterStart_Returns400()
    {
        var block = await CreateBlockAsync(Guid.NewGuid(), 9, 10);

        var response = await _admin.PutAsJsonAsync($"{Route}/{block.Id}", MondayRequest(12, 9));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Update_WhenNewHoursOverlapAnotherBlock_Returns409()
    {
        var teacherId = Guid.NewGuid();
        var block = await CreateBlockAsync(teacherId, 9, 10);
        await CreateBlockAsync(teacherId, 11, 12);

        var response = await _admin.PutAsJsonAsync($"{Route}/{block.Id}", MondayRequest(9, 12));

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Update_CancelsMeetingsLeftOutsideTheBlock()
    {
        var teacherId = Guid.NewGuid();
        var block = await CreateBlockAsync(teacherId, 9, 11);
        var inside = await BookAsync(teacherId, UpcomingMonday.AddHours(9));
        var outside = await BookAsync(teacherId, UpcomingMonday.AddHours(10));

        await _admin.PutAsJsonAsync($"{Route}/{block.Id}", MondayRequest(9, 10));

        Assert.Equal("Pending", await GetStatusAsync(inside.Id));
        Assert.Equal("Cancelled", await GetStatusAsync(outside.Id));
    }

    [Fact]
    public async Task Delete_WhenTeacherDeletesTheirBlock_Returns204AndCancelsItsMeetings()
    {
        var teacherId = Guid.NewGuid();
        var block = await CreateBlockAsync(teacherId, 9, 11);
        var meeting = await BookAsync(teacherId, UpcomingMonday.AddHours(9));

        var response = await TeacherClient(teacherId).DeleteAsync($"{Route}/{block.Id}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await _admin.GetAsync($"{Route}/{block.Id}")).StatusCode);
        Assert.Equal("Cancelled", await GetStatusAsync(meeting.Id));
    }

    [Fact]
    public async Task Delete_WhenRequesterIsAnotherTeacher_Returns403()
    {
        var block = await CreateBlockAsync(Guid.NewGuid(), 9, 10);

        var response = await TeacherClient(Guid.NewGuid()).DeleteAsync($"{Route}/{block.Id}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenBlockDoesNotExist_Returns404()
    {
        var response = await _admin.DeleteAsync($"{Route}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateAndDelete_WithoutToken_Return401()
    {
        var anonymous = factory.CreateClient();

        var update = await anonymous.PutAsJsonAsync($"{Route}/{Guid.NewGuid()}", MondayRequest(9, 10));
        var delete = await anonymous.DeleteAsync($"{Route}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Unauthorized, update.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, delete.StatusCode);
    }

    private HttpClient TeacherClient(Guid teacherId) => factory.CreateClientAs(teacherId, ScheduleApiFactory.TeacherRole);

    private static UpdateOfficeHourRequest MondayRequest(int startHour, int endHour) =>
        new(null, DayOfWeek.Monday, new TimeOnly(startHour, 0), new TimeOnly(endHour, 0));

    private async Task<OfficeHourDto> CreateBlockAsync(Guid teacherId, int startHour, int endHour)
    {
        var response = await _admin.PostAsJsonAsync(Route,
            new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Monday, new TimeOnly(startHour, 0), new TimeOnly(endHour, 0)));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<OfficeHourDto>())!;
    }

    private async Task<MeetingDto> BookAsync(Guid teacherId, DateTime scheduledAt)
    {
        var response = await _admin.PostAsJsonAsync("/api/schedule/meetings",
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, scheduledAt, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }

    private async Task<string> GetStatusAsync(Guid meetingId) =>
        (await _admin.GetFromJsonAsync<MeetingDto>($"/api/schedule/meetings/{meetingId}"))!.Status;
}
