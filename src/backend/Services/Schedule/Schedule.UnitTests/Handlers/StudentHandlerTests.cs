using ErrorOr;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class StudentHandlerTests
{
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
        var result = await _handler.GetMeetingsAsync(Guid.NewGuid(), To, From, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetMeetingsAsync_ReturnsOnlyThatStudentsMeetingsInRange()
    {
        var studentId = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, From.AddHours(10), 30));
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, To.AddDays(1), 30));
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddHours(10), 30));

        var result = await _handler.GetMeetingsAsync(studentId, From, To, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(studentId, result.Value.StudentRefId);
        Assert.Equal(1, result.Value.MeetingCount);
        Assert.Single(result.Value.Meetings);
    }

    [Fact]
    public async Task GetMeetingsAsync_WhenStudentHasNoMeetings_ReturnsEmptyList()
    {
        var result = await _handler.GetMeetingsAsync(Guid.NewGuid(), From, To, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(0, result.Value.MeetingCount);
        Assert.Empty(result.Value.Meetings);
    }
}
