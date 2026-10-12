using ErrorOr;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class OfficeHourHandlerTests
{
    private readonly FakeOfficeHourRepository _repository = new();
    private readonly OfficeHourHandler _handler;

    public OfficeHourHandlerTests()
    {
        _handler = new OfficeHourHandler(_repository);
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

        var result = await _handler.CreateAsync(request, CancellationToken.None);

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

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Empty(_repository.Items);
    }
}
