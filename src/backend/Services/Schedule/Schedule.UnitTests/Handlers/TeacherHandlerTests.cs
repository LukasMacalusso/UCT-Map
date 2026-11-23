using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class TeacherHandlerTests
{
    private static readonly Requester Admin = new(Guid.NewGuid(), IsAdmin: true);

    private static readonly DateTime From = new(2026, 10, 12);
    private static readonly DateTime To = new(2026, 10, 19);

    private readonly FakeOfficeHourRepository _officeHours = new();
    private readonly FakeMeetingRepository _meetings = new();
    private readonly TeacherHandler _handler;

    public TeacherHandlerTests()
    {
        _handler = new TeacherHandler(_officeHours, _meetings);
    }

    [Fact]
    public async Task GetWorkloadAsync_WhenToIsNotAfterFrom_ReturnsValidationError()
    {
        var result = await _handler.GetWorkloadAsync(Guid.NewGuid(), To, From, Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetWorkloadAsync_SumsWeeklyMinutesAndCountsMeetingsInRange()
    {
        var teacherId = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));
        _officeHours.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Wednesday, new TimeOnly(15, 0), new TimeOnly(15, 45)));
        _meetings.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, From.AddHours(9), 30));
        _meetings.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, To.AddDays(3), 30));

        var result = await _handler.GetWorkloadAsync(teacherId, From, To, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(165, result.Value.WeeklyOfficeHourMinutes);
        Assert.Equal(1, result.Value.MeetingCount);
        Assert.Equal(2, result.Value.OfficeHours.Count);
        Assert.Single(result.Value.Meetings);
    }

    [Fact]
    public async Task GetWorkloadAsync_WhenTeacherHasNoData_ReturnsEmptyWorkload()
    {
        var result = await _handler.GetWorkloadAsync(Guid.NewGuid(), From, To, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(0, result.Value.WeeklyOfficeHourMinutes);
        Assert.Equal(0, result.Value.MeetingCount);
        Assert.Empty(result.Value.OfficeHours);
    }

    [Fact]
    public async Task GetAvailabilityAsync_ReturnsTeachersOfficeHourBlocks()
    {
        var teacherId = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));
        _officeHours.Items.Add(new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));

        var result = await _handler.GetAvailabilityAsync(teacherId, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(teacherId, result.Value.TeacherRefId);
        Assert.Single(result.Value.AvailableBlocks);
    }

    [Fact]
    public async Task GetWorkloadAsync_WhenRequesterIsTheTeacher_ReturnsWorkload()
    {
        var teacherId = Guid.NewGuid();

        var result = await _handler.GetWorkloadAsync(teacherId, From, To, new Requester(teacherId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(teacherId, result.Value.TeacherRefId);
    }

    [Fact]
    public async Task GetWorkloadAsync_WhenRequesterIsAnotherUser_ReturnsForbidden()
    {
        var result = await _handler.GetWorkloadAsync(
            Guid.NewGuid(), From, To, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
    }
}
