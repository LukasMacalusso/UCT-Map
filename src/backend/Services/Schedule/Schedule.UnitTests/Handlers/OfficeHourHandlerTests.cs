using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.Domain.Enums;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class OfficeHourHandlerTests
{
    private static readonly Requester Admin = new(Guid.NewGuid(), IsAdmin: true);

    // "Now" is Sunday 2026-11-15; Monday 2026-11-16 is upcoming and Monday 2026-11-09 is in the past.
    private static readonly DateTime NextMonday = new(2026, 11, 16);
    private static readonly DateTime LastMonday = new(2026, 11, 9);

    private readonly FakeOfficeHourRepository _repository = new();
    private readonly FakeMeetingRepository _meetings = new();
    private readonly FakeUnitOfWork _unitOfWork = new();
    private readonly OfficeHourHandler _handler;

    public OfficeHourHandlerTests()
    {
        _handler = new OfficeHourHandler(_repository, _meetings, _unitOfWork, new CampusTimeZone(TimeZoneInfo.Utc),
            new FixedTimeProvider(new DateTimeOffset(2026, 11, 15, 12, 0, 0, TimeSpan.Zero)));
    }

    [Fact]
    public async Task GetByIdAsync_WhenOfficeHourExists_ReturnsDto()
    {
        var officeHour = new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0));
        _repository.Items.Add(officeHour);

        var result = await _handler.GetByIdAsync(officeHour.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(officeHour.Id, result.Value.Id);
        Assert.Equal("Monday", result.Value.DayOfWeek);
    }

    [Fact]
    public async Task GetByIdAsync_WhenOfficeHourDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.GetByIdAsync(Guid.NewGuid(), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAllAsync_ReturnsBlocksFromEveryTeacher()
    {
        _repository.Items.Add(new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));
        _repository.Items.Add(new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Friday, new TimeOnly(14, 0), new TimeOnly(15, 0)));

        var result = await _handler.GetAllAsync(CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(2, result.Value.Count());
    }

    [Fact]
    public async Task GetAllAsync_WhenThereAreNoBlocks_ReturnsEmptyList()
    {
        var result = await _handler.GetAllAsync(CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Empty(result.Value);
    }

    [Fact]
    public async Task GetByTeacherAsync_ReturnsOnlyThatTeachersBlocks()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Wednesday, new TimeOnly(15, 0), new TimeOnly(17, 0)));
        _repository.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));
        _repository.Items.Add(new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0)));

        var result = await _handler.GetByTeacherAsync(teacherId, CancellationToken.None);

        Assert.False(result.IsError);
        var blocks = result.Value.ToList();
        Assert.Equal(2, blocks.Count);
        Assert.All(blocks, b => Assert.Equal(teacherId, b.TeacherRefId));
        Assert.Equal("Monday", blocks[0].DayOfWeek);
    }

    [Fact]
    public async Task CreateAsync_WithValidRequest_PersistsAndReturnsDto()
    {
        var request = new CreateOfficeHourRequest(
            Guid.NewGuid(), Guid.NewGuid(), DayOfWeek.Tuesday, new TimeOnly(10, 0), new TimeOnly(12, 0));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(_repository.Items);
        Assert.Equal(request.TeacherRefId, result.Value.TeacherRefId);
        Assert.Equal(request.StructureRefId, result.Value.StructureRefId);
    }

    [Fact]
    public async Task CreateAsync_WhenEndIsNotAfterStart_ReturnsValidationErrorAndDoesNotPersist()
    {
        var request = new CreateOfficeHourRequest(
            Guid.NewGuid(), null, DayOfWeek.Tuesday, new TimeOnly(12, 0), new TimeOnly(10, 0));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenTeacherCreatesTheirOwnBlock_Persists()
    {
        var teacherId = Guid.NewGuid();
        var request = new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));

        var result = await _handler.CreateAsync(request, new Requester(teacherId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Single(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenRequesterIsAnotherUser_ReturnsForbiddenAndDoesNotPersist()
    {
        var request = new CreateOfficeHourRequest(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));

        var result = await _handler.CreateAsync(request, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Theory]
    [InlineData(9, 30, 10, 30)]
    [InlineData(8, 0, 12, 0)]
    [InlineData(9, 15, 9, 45)]
    public async Task CreateAsync_WhenTeacherHasAnOverlappingBlock_ReturnsConflict(int startHour, int startMinute, int endHour, int endMinute)
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));
        var request = new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Monday,
            new TimeOnly(startHour, startMinute), new TimeOnly(endHour, endMinute));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("teacher", result.FirstError.Description);
        Assert.Single(_repository.Items);
    }

    [Fact]
    public async Task CreateAsync_WhenRoomHasAnOverlappingBlock_ReturnsConflict()
    {
        var roomId = Guid.NewGuid();
        _repository.Items.Add(new OfficeHour(Guid.NewGuid(), roomId, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));
        var request = new CreateOfficeHourRequest(Guid.NewGuid(), roomId, DayOfWeek.Monday, new TimeOnly(9, 30), new TimeOnly(11, 0));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Contains("room", result.FirstError.Description);
    }

    [Fact]
    public async Task CreateAsync_WhenBlockStartsExactlyWhenAnotherEnds_Persists()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));
        var request = new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Monday, new TimeOnly(10, 0), new TimeOnly(11, 0));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(2, _repository.Items.Count);
    }

    [Fact]
    public async Task CreateAsync_WhenSameHoursAreOnAnotherDayOrForAnotherTeacher_Persists()
    {
        var teacherId = Guid.NewGuid();
        _repository.Items.Add(new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)));

        var otherDay = await _handler.CreateAsync(
            new CreateOfficeHourRequest(teacherId, null, DayOfWeek.Tuesday, new TimeOnly(9, 0), new TimeOnly(10, 0)), Admin, CancellationToken.None);
        var otherTeacher = await _handler.CreateAsync(
            new CreateOfficeHourRequest(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0)), Admin, CancellationToken.None);

        Assert.False(otherDay.IsError);
        Assert.False(otherTeacher.IsError);
    }

    [Fact]
    public async Task CreateAsync_WhenTransactionHitsAConcurrentWrite_ReturnsConflict()
    {
        _unitOfWork.SimulateConcurrencyConflict = true;
        var request = new CreateOfficeHourRequest(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));

        var result = await _handler.CreateAsync(request, Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }

    [Fact]
    public async Task UpdateAsync_WhenOfficeHourDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.UpdateAsync(Guid.NewGuid(), MondayRequest(9, 11), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Fact]
    public async Task UpdateAsync_WhenRequesterIsAnotherUser_ReturnsForbidden()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);

        var result = await _handler.UpdateAsync(block.Id, MondayRequest(9, 11), new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Equal(new TimeOnly(10, 0), block.EndTime);
    }

    [Fact]
    public async Task UpdateAsync_WhenTeacherEditsTheirBlock_SavesTheNewHours()
    {
        var teacherId = Guid.NewGuid();
        var block = AddBlock(teacherId, 9, 10);
        var roomId = Guid.NewGuid();

        var result = await _handler.UpdateAsync(block.Id,
            new UpdateOfficeHourRequest(roomId, DayOfWeek.Tuesday, new TimeOnly(14, 0), new TimeOnly(16, 0)),
            new Requester(teacherId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Tuesday", result.Value.DayOfWeek);
        Assert.Equal(new TimeOnly(14, 0), block.StartTime);
        Assert.Equal(roomId, block.StructureRefId);
        Assert.Equal(teacherId, block.TeacherRefId);
    }

    [Fact]
    public async Task UpdateAsync_WhenEndIsNotAfterStart_ReturnsValidationError()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);

        var result = await _handler.UpdateAsync(block.Id, MondayRequest(11, 9), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task UpdateAsync_WhenNewHoursOverlapAnotherBlockOfTheTeacher_ReturnsConflict()
    {
        var teacherId = Guid.NewGuid();
        var block = AddBlock(teacherId, 9, 10);
        AddBlock(teacherId, 11, 12);

        var result = await _handler.UpdateAsync(block.Id, MondayRequest(9, 12), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
    }

    [Fact]
    public async Task UpdateAsync_WhenNewHoursOnlyOverlapTheSameBlock_IsAccepted()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);

        var result = await _handler.UpdateAsync(block.Id, MondayRequest(9, 11), Admin, CancellationToken.None);

        Assert.False(result.IsError);
    }

    [Fact]
    public async Task UpdateAsync_CancelsOnlyUpcomingMeetingsLeftOutsideTheNewHours()
    {
        var teacherId = Guid.NewGuid();
        var block = AddBlock(teacherId, 9, 11);
        var stillInside = AddMeeting(teacherId, NextMonday.AddHours(9));
        var leftOutside = AddMeeting(teacherId, NextMonday.AddHours(10));
        var past = AddMeeting(teacherId, LastMonday.AddHours(10));

        await _handler.UpdateAsync(block.Id, MondayRequest(9, 10), Admin, CancellationToken.None);

        Assert.Equal(MeetingStatus.Pending, stillInside.Status);
        Assert.Equal(MeetingStatus.Cancelled, leftOutside.Status);
        Assert.Equal(MeetingStatus.Pending, past.Status);
        Assert.Equal([leftOutside.Id], _meetings.UpdatedIds);
    }

    [Fact]
    public async Task UpdateAsync_WhenTransactionHitsAConcurrentWrite_ReturnsConflict()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);
        _unitOfWork.SimulateConcurrencyConflict = true;

        var result = await _handler.UpdateAsync(block.Id, MondayRequest(9, 11), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
    }

    [Fact]
    public async Task DeleteAsync_WhenOfficeHourDoesNotExist_ReturnsNotFound()
    {
        var result = await _handler.DeleteAsync(Guid.NewGuid(), Admin, CancellationToken.None);

        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
    }

    [Fact]
    public async Task DeleteAsync_WhenRequesterIsAnotherUser_ReturnsForbiddenAndKeepsTheBlock()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);

        var result = await _handler.DeleteAsync(block.Id, new Requester(Guid.NewGuid(), IsAdmin: false), CancellationToken.None);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Single(_repository.Items);
    }

    [Fact]
    public async Task DeleteAsync_RemovesTheBlockAndCancelsItsUpcomingMeetings()
    {
        var teacherId = Guid.NewGuid();
        var block = AddBlock(teacherId, 9, 11);
        AddBlock(teacherId, 14, 15);
        var inside = AddMeeting(teacherId, NextMonday.AddHours(9));
        var confirmed = AddMeeting(teacherId, NextMonday.AddHours(10));
        confirmed.Confirm();
        var inAnotherBlock = AddMeeting(teacherId, NextMonday.AddHours(14));
        var past = AddMeeting(teacherId, LastMonday.AddHours(9));

        var result = await _handler.DeleteAsync(block.Id, new Requester(teacherId, IsAdmin: false), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.DoesNotContain(block, _repository.Items);
        Assert.Equal(MeetingStatus.Cancelled, inside.Status);
        Assert.Equal(MeetingStatus.Cancelled, confirmed.Status);
        Assert.Equal(MeetingStatus.Pending, inAnotherBlock.Status);
        Assert.Equal(MeetingStatus.Pending, past.Status);
    }

    [Fact]
    public async Task DeleteAsync_WhenTransactionHitsAConcurrentWrite_ReturnsConflict()
    {
        var block = AddBlock(Guid.NewGuid(), 9, 10);
        _unitOfWork.SimulateConcurrencyConflict = true;

        var result = await _handler.DeleteAsync(block.Id, Admin, CancellationToken.None);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
    }

    private static UpdateOfficeHourRequest MondayRequest(int startHour, int endHour) =>
        new(null, DayOfWeek.Monday, new TimeOnly(startHour, 0), new TimeOnly(endHour, 0));

    private OfficeHour AddBlock(Guid teacherId, int startHour, int endHour)
    {
        var block = new OfficeHour(teacherId, null, DayOfWeek.Monday, new TimeOnly(startHour, 0), new TimeOnly(endHour, 0));
        _repository.Items.Add(block);
        return block;
    }

    private Meeting AddMeeting(Guid teacherId, DateTime scheduledAt)
    {
        var meeting = new Meeting(teacherId, Guid.NewGuid(), null, scheduledAt, 30);
        _meetings.Items.Add(meeting);
        return meeting;
    }
}
