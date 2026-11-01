using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class MeetingStatusEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/meetings";
    private static readonly DateTime TenAm = new(2026, 11, 23, 10, 0, 0);

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task UpdateStatus_WhenStudentCancels_Returns200AndPersists()
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, "Cancelled", meeting.StudentRefId);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Cancelled", (await response.Content.ReadFromJsonAsync<MeetingDto>())!.Status);
        Assert.Equal("Cancelled", await GetStoredStatusAsync(meeting.Id));
    }

    [Fact]
    public async Task UpdateStatus_WhenTeacherCancels_Returns200()
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, "Cancelled", meeting.TeacherRefId);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_WhenCancelled_FreesTheSlotForANewMeeting()
    {
        var meeting = await BookAsync();
        await UpdateStatusAsync(meeting.Id, "Cancelled", meeting.StudentRefId);

        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(meeting.TeacherRefId, Guid.NewGuid(), null, meeting.ScheduledAt, 30));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_WhenTeacherConfirmsAndCompletes_Persists()
    {
        var meeting = await BookAsync();

        var confirmed = await UpdateStatusAsync(meeting.Id, "Confirmed", meeting.TeacherRefId);
        Assert.Equal(HttpStatusCode.OK, confirmed.StatusCode);
        Assert.Equal("Confirmed", await GetStoredStatusAsync(meeting.Id));

        var completed = await UpdateStatusAsync(meeting.Id, "Completed", meeting.TeacherRefId);
        Assert.Equal(HttpStatusCode.OK, completed.StatusCode);
        Assert.Equal("Completed", await GetStoredStatusAsync(meeting.Id));
    }

    [Fact]
    public async Task UpdateStatus_WhenStudentConfirms_Returns403()
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, "Confirmed", meeting.StudentRefId);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("Pending", await GetStoredStatusAsync(meeting.Id));
    }

    [Fact]
    public async Task UpdateStatus_WhenRequesterIsAnotherUser_Returns403AndKeepsTheMeeting()
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, "Cancelled", Guid.NewGuid());

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        Assert.Equal("Pending", await GetStoredStatusAsync(meeting.Id));
    }

    [Fact]
    public async Task UpdateStatus_WithoutToken_Returns401()
    {
        var meeting = await BookAsync();

        var response = await _client.PatchAsJsonAsync($"{Route}/{meeting.Id}/status", new UpdateMeetingStatusRequest("Cancelled"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_WhenMeetingDoesNotExist_Returns404()
    {
        var response = await UpdateStatusAsync(Guid.NewGuid(), "Cancelled", Guid.NewGuid());

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Theory]
    [InlineData("Pending")]
    [InlineData("Unknown")]
    public async Task UpdateStatus_WhenStatusIsNotAllowed_Returns400(string status)
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, status, meeting.TeacherRefId);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_WhenAlreadyCancelled_Returns409()
    {
        var meeting = await BookAsync();
        await UpdateStatusAsync(meeting.Id, "Cancelled", meeting.StudentRefId);

        var response = await UpdateStatusAsync(meeting.Id, "Cancelled", meeting.StudentRefId);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_WhenCompletingAPendingMeeting_Returns409()
    {
        var meeting = await BookAsync();

        var response = await UpdateStatusAsync(meeting.Id, "Completed", meeting.TeacherRefId);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    private async Task<MeetingDto> BookAsync()
    {
        var response = await _client.PostAsJsonAsync(Route,
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30));
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<MeetingDto>())!;
    }

    private Task<HttpResponseMessage> UpdateStatusAsync(Guid meetingId, string status, Guid requesterId)
    {
        var request = new HttpRequestMessage(HttpMethod.Patch, $"{Route}/{meetingId}/status")
        {
            Content = JsonContent.Create(new UpdateMeetingStatusRequest(status))
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(requesterId));
        return _client.SendAsync(request);
    }

    private async Task<string> GetStoredStatusAsync(Guid meetingId)
    {
        var stored = await _client.GetFromJsonAsync<MeetingDto>($"{Route}/{meetingId}");
        return stored!.Status;
    }

    // Same claim Identity puts in its tokens. Schedule does not check the signature (the gateway does).
    private static string CreateToken(Guid userId)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));
        var token = new JwtSecurityToken(
            claims: [new Claim(JwtRegisteredClaimNames.Sub, userId.ToString())],
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
