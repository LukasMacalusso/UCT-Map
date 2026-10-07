using Schedule.Domain.Entities;

namespace Schedule.UnitTests.Domain;

public class OfficeHourTests
{
    [Fact]
    public void Constructor_WithValidRange_SetsAllProperties()
    {
        var teacherId = Guid.NewGuid();
        var structureId = Guid.NewGuid();

        var officeHour = new OfficeHour(
            teacherId, structureId, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0));

        Assert.NotEqual(Guid.Empty, officeHour.Id);
        Assert.Equal(teacherId, officeHour.TeacherRefId);
        Assert.Equal(structureId, officeHour.StructureRefId);
        Assert.Equal(DayOfWeek.Monday, officeHour.DayOfWeek);
        Assert.Equal(new TimeOnly(9, 0), officeHour.StartTime);
        Assert.Equal(new TimeOnly(11, 0), officeHour.EndTime);
    }

    [Fact]
    public void Constructor_WithoutStructure_AllowsNullStructure()
    {
        var officeHour = new OfficeHour(
            Guid.NewGuid(), null, DayOfWeek.Friday, new TimeOnly(14, 0), new TimeOnly(15, 0));

        Assert.Null(officeHour.StructureRefId);
    }

    [Theory]
    [InlineData(11, 0, 9, 0)]
    [InlineData(10, 0, 10, 0)]
    public void Constructor_WhenEndIsNotAfterStart_ThrowsArgumentException(
        int startHour, int startMinute, int endHour, int endMinute)
    {
        var exception = Assert.Throws<ArgumentException>(() => new OfficeHour(
            Guid.NewGuid(),
            null,
            DayOfWeek.Monday,
            new TimeOnly(startHour, startMinute),
            new TimeOnly(endHour, endMinute)));

        Assert.Equal("endTime", exception.ParamName);
    }

    [Fact]
    public void Constructor_GeneratesUniqueIds()
    {
        var first = new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));
        var second = new OfficeHour(Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(10, 0));

        Assert.NotEqual(first.Id, second.Id);
    }
}
