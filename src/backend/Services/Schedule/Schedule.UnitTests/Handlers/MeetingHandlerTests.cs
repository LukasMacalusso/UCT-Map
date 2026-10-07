using ErrorOr;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class MeetingHandlerTests
{
    private static readonly DateTime From = new(2026, 10, 12);
    private static readonly DateTime To = new(2026, 10, 19);

    private static readonly DateTime TenAm = new(2026, 10, 12, 10, 0, 0);

    private readonly FakeMeetingRepository _repository = new();
    private readonly FakeUnitOfWork _unitOfWork = new();
    private readonly MeetingHandler _handler;

    public MeetingHandlerTests()
    {
        _handler = new MeetingHandler(_repository, _unitOfWork);
    }

    [Fact]
    public async Task GetByIdAsync_WhenMeetingExists_ReturnsDto()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddHours(10), 30);
        _repository.Items.Add(meeting);

        var result = await _handler.GetByIdAsync(meeting.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(meeting.Id, result.Value.Id);
        Assert.Equal("Pending", result.Value.Status);
    }

    [Fact]
    public async Task GetByIdAsync_WhenMeetingDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.GetByIdAsync(Guid.NewGuid(), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsEveryMeetingOrderedByDate()
    {
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddDays(3), 30));
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddDays(1), 30));

        var result = await _handler.GetAllAsync(CancellationToken.None);

        Assert.False(result.IsError);
        var meetings = result.Value.ToList();
        Assert.Equal(2, meetings.Count);
        Assert.True(meetings[0].ScheduledAt < meetings[1].ScheduledAt);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task GetByTeacherAsync_WhenToIsNotAfterFrom_ReturnsValidationError(int daysOffset)
    {
        var result = await _handler.GetByTeacherAsync(Guid.NewGuid(), From, From.AddDays(daysOffset), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetByTeacherAsync_ReturnsOnlyMeetingsWithinRange()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, From.AddDays(1), 30));
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, To.AddDays(1), 30));
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddDays(1), 30));

        var result = await _handler.GetByTeacherAsync(teacherId, From, To, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(result.Value);
    }

    [Fact]
    public async Task CreateAsync_PersistsMeetingInPendingStatus()
    {
        var request = new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), From.AddHours(9), 45);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(_repository.Items);
        Assert.Equal("Pending", result.Value.Status);
        Assert.Equal(45, result.Value.DurationMinutes);
    }

    [Fact]
    public async Task CreateAsync_WhenDurationIsNotPositive_ReturnsValidationErrorAndDoesNotPersist()
    {
        var request = new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 0);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenTeacherHasOverlappingMeeting_ReturnsConflict()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(15), 30), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("teacher", result.FirstError.Description);
        Assert.Single(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenStudentHasOverlappingMeeting_ReturnsConflict()
    {
        var studentId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(Guid.NewGuid(), studentId, null, TenAm, 60));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(Guid.NewGuid(), studentId, null, TenAm.AddMinutes(30), 30), CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("student", result.FirstError.Description);
    }

    [Fact]
    public async Task CreateAsync_WhenRoomIsBookedAtThatTime_ReturnsConflict()
    {
        var roomId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), roomId, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), roomId, TenAm, 30), CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("room", result.FirstError.Description);
    }

    [Fact]
    public async Task CreateAsync_WhenMeetingStartsExactlyWhenAnotherEnds_IsAccepted()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(30), 30), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(2, _repository.Items.Count);
    }

    [Fact]
    public async Task CreateAsync_WhenOnlyTheTimeMatchesButNobodyIsShared_IsAccepted()
    {
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30), CancellationToken.None);

        Assert.False(result.IsError);
    }

    [Fact]
    public async Task CreateAsync_WhenAConcurrentRequestWinsTheSlot_ReturnsConflict()
    {
        _unitOfWork.SimulateConcurrencyConflict = true;

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }
}
