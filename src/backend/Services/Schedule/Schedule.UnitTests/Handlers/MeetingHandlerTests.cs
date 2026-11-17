using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.Domain.Enums;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class MeetingHandlerTests
{
    private static readonly Requester Admin = new(Guid.NewGuid(), IsAdmin: true);

    private static readonly DateTime From = new(2026, 10, 12);
    private static readonly DateTime To = new(2026, 10, 19);

    private static readonly DateTime TenAm = new(2026, 10, 12, 10, 0, 0);

    private readonly FakeMeetingRepository _repository = new();
    private readonly FakeOfficeHourRepository _officeHours = new();
    private readonly FakeUnitOfWork _unitOfWork = new();
    private readonly MeetingHandler _handler;

    public MeetingHandlerTests()
    {
        _handler = new MeetingHandler(_repository, _officeHours, _unitOfWork, new CampusTimeZone(TimeZoneInfo.Utc));
    }

    [Fact]
    public async Task GetByIdAsync_WhenMeetingExists_ReturnsDto()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddHours(10), 30);
        _repository.Items.Add(meeting);

        var result = await _handler.GetByIdAsync(meeting.Id, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(meeting.Id, result.Value.Id);
        Assert.Equal("Pending", result.Value.Status);
    }

    [Fact]
    public async Task GetByIdAsync_WhenMeetingDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.GetByIdAsync(Guid.NewGuid(), Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsEveryMeetingOrderedByDate()
    {
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddDays(3), 30));
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, From.AddDays(1), 30));

        var result = await _handler.GetAllAsync(Admin, CancellationToken.None);

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
        var request = new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), Guid.NewGuid(), From.AddHours(9), 45);

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(_repository.Items);
        Assert.Equal("Pending", result.Value.Status);
        Assert.Equal(45, result.Value.DurationMinutes);
    }

    [Fact]
    public async Task CreateAsync_WhenDurationIsNotPositive_ReturnsValidationErrorAndDoesNotPersist()
    {
        var request = new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), null, TenAm, 0);

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenTeacherHasOverlappingMeeting_ReturnsConflict()
    {
        var teacherId = TeacherWithOpenHours();
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(15), 30), Admin, CancellationToken.None);

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
            new CreateMeetingRequest(TeacherWithOpenHours(), studentId, null, TenAm.AddMinutes(30), 30), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("student", result.FirstError.Description);
    }

    [Fact]
    public async Task CreateAsync_WhenRoomIsBookedAtThatTime_ReturnsConflict()
    {
        var roomId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), roomId, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), roomId, TenAm, 30), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("room", result.FirstError.Description);
    }

    [Fact]
    public async Task CreateAsync_WhenMeetingStartsExactlyWhenAnotherEnds_IsAccepted()
    {
        var teacherId = TeacherWithOpenHours();
        _repository.Items.Add(new Meeting(teacherId, Guid.NewGuid(), null, TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.AddMinutes(30), 30), Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(2, _repository.Items.Count);
    }

    [Fact]
    public async Task CreateAsync_WhenOnlyTheTimeMatchesButNobodyIsShared_IsAccepted()
    {
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), TenAm, 30));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), null, TenAm, 30), Admin, CancellationToken.None);

        Assert.False(result.IsError);
    }

    [Fact]
    public async Task CreateAsync_WhenAConcurrentRequestWinsTheSlot_ReturnsConflict()
    {
        _unitOfWork.SimulateConcurrencyConflict = true;

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), null, TenAm, 30), Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Theory]
    [InlineData("Cancelled")]
    [InlineData("cancelled")]
    public async Task UpdateStatusAsync_WhenStudentCancels_CancelsAndSaves(string status)
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, status, meeting.StudentRefId, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Cancelled", result.Value.Status);
        Assert.Equal(MeetingStatus.Cancelled, meeting.Status);
        Assert.Contains(meeting.Id, _repository.UpdatedIds);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenTeacherCancels_Cancels()
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, "Cancelled", meeting.TeacherRefId, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Cancelled", result.Value.Status);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenTeacherConfirms_ConfirmsAndSaves()
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, "Confirmed", meeting.TeacherRefId, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Confirmed", result.Value.Status);
        Assert.Contains(meeting.Id, _repository.UpdatedIds);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenTeacherCompletesConfirmedMeeting_Completes()
    {
        var meeting = AddMeeting();
        meeting.Confirm();

        var result = await _handler.UpdateStatusAsync(meeting.Id, "Completed", meeting.TeacherRefId, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Completed", result.Value.Status);
    }

    [Theory]
    [InlineData("Confirmed")]
    [InlineData("Completed")]
    public async Task UpdateStatusAsync_WhenStudentConfirmsOrCompletes_ReturnsForbiddenAndDoesNotSave(string status)
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, status, meeting.StudentRefId, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Equal(MeetingStatus.Pending, meeting.Status);
        Assert.Empty(_repository.UpdatedIds);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenRequesterIsNotAParticipant_ReturnsForbiddenAndDoesNotSave()
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, "Cancelled", Guid.NewGuid(), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Equal(MeetingStatus.Pending, meeting.Status);
        Assert.Empty(_repository.UpdatedIds);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenMeetingDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.UpdateStatusAsync(Guid.NewGuid(), "Cancelled", Guid.NewGuid(), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Theory]
    [InlineData("Pending")]
    [InlineData("2")]
    [InlineData("")]
    [InlineData("Unknown")]
    public async Task UpdateStatusAsync_WhenStatusIsNotAllowed_ReturnsValidationErrorAndDoesNotSave(string status)
    {
        var meeting = AddMeeting();

        var result = await _handler.UpdateStatusAsync(meeting.Id, status, meeting.TeacherRefId, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Empty(_repository.UpdatedIds);
    }

    [Fact]
    public async Task UpdateStatusAsync_WhenTransitionIsNotAllowed_ReturnsConflictAndDoesNotSave()
    {
        var meeting = AddMeeting();
        meeting.Cancel();

        var result = await _handler.UpdateStatusAsync(meeting.Id, "Confirmed", meeting.TeacherRefId, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Empty(_repository.UpdatedIds);
    }

    [Fact]
    public async Task GetByIdAsync_WhenRequesterIsTheStudent_ReturnsDto()
    {
        var meeting = AddMeeting();

        var result = await _handler.GetByIdAsync(meeting.Id, new Requester(meeting.StudentRefId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(meeting.Id, result.Value.Id);
    }

    [Fact]
    public async Task GetByIdAsync_WhenRequesterIsNotAParticipant_ReturnsForbidden()
    {
        var meeting = AddMeeting();

        var result = await _handler.GetByIdAsync(meeting.Id, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAllAsync_WhenRequesterIsNotAdmin_ReturnsOnlyTheMeetingsTheyTakePartIn()
    {
        var userId = Guid.NewGuid();
        _repository.Items.Add(new Meeting(Guid.NewGuid(), userId, null, TenAm, 30));
        _repository.Items.Add(new Meeting(userId, Guid.NewGuid(), null, TenAm.AddHours(1), 30));
        _repository.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30));

        var result = await _handler.GetAllAsync(new Requester(userId, IsAdmin: false), CancellationToken.None);

        Assert.Equal(2, result.Value.Count());
        Assert.All(result.Value, m => Assert.True(m.StudentRefId == userId || m.TeacherRefId == userId));
    }

    [Fact]
    public async Task CreateAsync_WhenStudentBooksForThemselves_IsAccepted()
    {
        var studentId = Guid.NewGuid();
        var request = new CreateMeetingRequest(TeacherWithOpenHours(), studentId, null, TenAm, 30);

        var result = await _handler.CreateAsync(request, new Requester(studentId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenRequesterIsNotAParticipant_ReturnsForbiddenAndDoesNotPersist()
    {
        var request = new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), null, TenAm, 30);

        var result = await _handler.CreateAsync(request, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenTeacherHasNoOfficeHours_ReturnsValidationErrorAndDoesNotPersist()
    {
        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Contains("office hours", result.FirstError.Description);
        Assert.Empty(_repository.Items);
    }

    [Theory]
    [InlineData(9, 0, 60, true)]
    [InlineData(9, 15, 30, true)]
    [InlineData(9, 45, 30, false)]
    [InlineData(8, 45, 30, false)]
    [InlineData(10, 0, 30, false)]
    public async Task CreateAsync_RequiresTheMeetingInsideAnOfficeHourOfThatDay(int hour, int minute, int duration, bool accepted)
    {
        var teacherId = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(teacherId, null, TenAm.DayOfWeek, new TimeOnly(9, 0), new TimeOnly(10, 0)));

        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, TenAm.Date.AddHours(hour).AddMinutes(minute), duration),
            Admin, CancellationToken.None);

        Assert.Equal(accepted, !result.IsError);
    }

    [Fact]
    public async Task CreateAsync_WhenMeetingCrossesMidnight_ReturnsValidationError()
    {
        var result = await _handler.CreateAsync(
            new CreateMeetingRequest(TeacherWithOpenHours(), Guid.NewGuid(), null, TenAm.Date.AddHours(23).AddMinutes(45), 30),
            Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Theory]
    [InlineData(13, true)]
    [InlineData(10, false)]
    public async Task CreateAsync_ComparesTheUtcMeetingWithOfficeHoursInCampusTime(int utcHour, bool accepted)
    {
        // Tuesday 2026-11-17: Santiago is UTC-3, so 13:00 UTC is 10:00 on campus.
        var handler = new MeetingHandler(_repository, _officeHours, _unitOfWork, CampusTimeZone.FromId("America/Santiago"));
        var teacherId = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Tuesday, new TimeOnly(10, 0), new TimeOnly(11, 0)));

        var result = await handler.CreateAsync(
            new CreateMeetingRequest(teacherId, Guid.NewGuid(), null, new DateTime(2026, 11, 17, utcHour, 0, 0), 30),
            Admin, CancellationToken.None);

        Assert.Equal(accepted, !result.IsError);
    }

    // Gives the teacher an office hour covering every day, so only the rule under test can reject the meeting.
    private Guid TeacherWithOpenHours()
    {
        var teacherId = Guid.NewGuid();
        foreach (var day in Enum.GetValues<DayOfWeek>())
            _officeHours.Items.Add(new OfficeHour(teacherId, null, day, TimeOnly.MinValue, TimeOnly.MaxValue));
        return teacherId;
    }

    private Meeting AddMeeting()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, TenAm, 30);
        _repository.Items.Add(meeting);
        return meeting;
    }
}
