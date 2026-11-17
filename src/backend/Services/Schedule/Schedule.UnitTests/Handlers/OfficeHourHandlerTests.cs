using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class OfficeHourHandlerTests
{
    private static readonly Requester Admin = new(Guid.NewGuid(), IsAdmin: true);

    private readonly FakeOfficeHourRepository _repository = new();
    private readonly FakeUnitOfWork _unitOfWork = new();
    private readonly OfficeHourHandler _handler;

    public OfficeHourHandlerTests()
    {
        _handler = new OfficeHourHandler(_repository, _unitOfWork);
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
}
