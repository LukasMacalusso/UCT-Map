using ErrorOr;
using Schedule.Application.Handlers;
using Schedule.Domain.Entities;
using Schedule.UnitTests.Fakes;

namespace Schedule.UnitTests.Handlers;

public class RoomHandlerTests
{
    private static readonly DateTime Monday = new(2026, 11, 2);
    private static readonly DateTime TenAm = Monday.AddHours(10);
    private static readonly DateTime ElevenAm = Monday.AddHours(11);

    private readonly FakeMeetingRepository _meetings = new();
    private readonly FakeOfficeHourRepository _officeHours = new();
    private readonly RoomHandler _handler;

    public RoomHandlerTests()
    {
        _handler = new RoomHandler(_meetings, _officeHours);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenRoomHasNoActivity_ReturnsItAsFree()
    {
        var room = Guid.NewGuid();

        var result = await _handler.GetAvailabilityAsync([room], TenAm, ElevenAm, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal([room], result.Value.FreeRoomIds);
        Assert.Empty(result.Value.Occupancies);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenAMeetingOverlaps_ReturnsRoomAsOccupiedByMeeting()
    {
        var room = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), room, TenAm.AddMinutes(15), 30));

        var result = await _handler.GetAvailabilityAsync([room], TenAm, ElevenAm, CancellationToken.None);

        Assert.Empty(result.Value.FreeRoomIds);
        var occupancy = Assert.Single(result.Value.Occupancies);
        Assert.Equal(room, occupancy.StructureRefId);
        Assert.Equal(RoomHandler.MeetingReason, occupancy.Reason);
        Assert.Equal(TenAm.AddMinutes(15), occupancy.OccupiedFrom);
        Assert.Equal(TenAm.AddMinutes(45), occupancy.OccupiedUntil);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenAnOfficeHourCoversTheSlot_ReturnsRoomAsOccupiedByOfficeHour()
    {
        var room = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(Guid.NewGuid(), room, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(12, 0)));

        var result = await _handler.GetAvailabilityAsync([room], TenAm, ElevenAm, CancellationToken.None);

        Assert.Empty(result.Value.FreeRoomIds);
        var occupancy = Assert.Single(result.Value.Occupancies);
        Assert.Equal(RoomHandler.OfficeHourReason, occupancy.Reason);
        Assert.Equal(Monday.AddHours(9), occupancy.OccupiedFrom);
        Assert.Equal(Monday.AddHours(12), occupancy.OccupiedUntil);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenOfficeHourIsOnAnotherWeekday_ReturnsRoomAsFree()
    {
        var room = Guid.NewGuid();
        _officeHours.Items.Add(new OfficeHour(Guid.NewGuid(), room, DayOfWeek.Tuesday, new TimeOnly(9, 0), new TimeOnly(12, 0)));

        var result = await _handler.GetAvailabilityAsync([room], TenAm, ElevenAm, CancellationToken.None);

        Assert.Equal([room], result.Value.FreeRoomIds);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenMeetingEndsExactlyAtStart_ReturnsRoomAsFree()
    {
        var room = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), room, TenAm.AddMinutes(-30), 30));

        var result = await _handler.GetAvailabilityAsync([room], TenAm, ElevenAm, CancellationToken.None);

        Assert.Equal([room], result.Value.FreeRoomIds);
    }

    [Fact]
    public async Task GetAvailabilityAsync_SplitsFreeAndOccupiedRoomsAndRemovesDuplicates()
    {
        Guid free = Guid.NewGuid(), busy = Guid.NewGuid();
        _meetings.Items.Add(new Meeting(Guid.NewGuid(), Guid.NewGuid(), busy, TenAm, 30));

        var result = await _handler.GetAvailabilityAsync([free, busy, free], TenAm, ElevenAm, CancellationToken.None);

        Assert.Equal([free], result.Value.FreeRoomIds);
        Assert.Equal(busy, Assert.Single(result.Value.Occupancies).StructureRefId);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenNoRoomsAreGiven_ReturnsValidationError()
    {
        var result = await _handler.GetAvailabilityAsync([], TenAm, ElevenAm, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenARoomIdIsEmpty_ReturnsValidationError()
    {
        var result = await _handler.GetAvailabilityAsync([Guid.Empty], TenAm, ElevenAm, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenToIsNotAfterFrom_ReturnsValidationError()
    {
        var result = await _handler.GetAvailabilityAsync([Guid.NewGuid()], ElevenAm, TenAm, CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task GetAvailabilityAsync_WhenRangeSpansTwoDays_ReturnsValidationError()
    {
        var result = await _handler.GetAvailabilityAsync([Guid.NewGuid()], TenAm, TenAm.AddDays(1), CancellationToken.None);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }
}
