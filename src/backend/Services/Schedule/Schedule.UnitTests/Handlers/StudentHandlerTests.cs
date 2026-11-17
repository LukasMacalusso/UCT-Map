using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class StudentHandlerTests
{
    private static readonly Requester Admin = new(Guid.NewGuid(), IsAdmin: true);

    private static readonly DateTime From = new(2026, 10, 12);
    private static readonly DateTime To = new(2026, 10, 19);

    private readonly FakeMeetingRepository _meetings = new();
    private readonly StudentHandler _handler;

    public StudentHandlerTests()
    {
        _handler = new StudentHandler(_meetings);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenToIsNotAfterFrom_ReturnsValidationError()
    {
        var result = await _handler.GetMeetingsAsync(Guid.NewGuid(), To, From, Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenDatesAreUtc_StoresThemWithoutKind()
    {
        var result = await _handler.GetMeetingsAsync(Guid.NewGuid(),
            DateTime.SpecifyKind(From, DateTimeKind.Utc), DateTime.SpecifyKind(To, DateTimeKind.Utc), Admin, CancellationToken.None);

        Assert.Equal(DateTimeKind.Unspecified, result.Value.From.Kind);
        Assert.Equal(DateTimeKind.Unspecified, result.Value.To.Kind);
    }

    [Fact]
    public async Task GetMeetingsAsync_ReturnsOnlyThatStudentsMeetingsInRange()
    {
        var studentId = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, From.AddHours(10), 30));
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, To.AddDays(1), 30));
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddHours(10), 30));

        var result = await _handler.GetMeetingsAsync(studentId, From, To, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(studentId, result.Value.StudentRefId);
        Assert.Equal(1, result.Value.MeetingCount);
        Assert.Single(result.Value.Meetings);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenStudentHasNoMeetings_ReturnsEmptyList()
    {
        var result = await _handler.GetMeetingsAsync(Guid.NewGuid(), From, To, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(0, result.Value.MeetingCount);
        Assert.Empty(result.Value.Meetings);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenRequesterIsTheStudent_ReturnsTheirMeetings()
    {
        var studentId = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, From.AddHours(10), 30));

        var result = await _handler.GetMeetingsAsync(studentId, From, To, new Requester(studentId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(1, result.Value.MeetingCount);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenRequesterIsAnotherUser_ReturnsForbidden()
    {
        var result = await _handler.GetMeetingsAsync(
            Guid.NewGuid(), From, To, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
    }
}
