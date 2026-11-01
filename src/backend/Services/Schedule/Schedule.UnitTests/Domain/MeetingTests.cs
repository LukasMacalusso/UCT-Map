using Schedule.Domain.Entities;
using Schedule.Domain.Enums;

namespace Schedule.UnitTests.Domain;

public class MeetingTests
{
    [Fact]
    public void Constructor_SetsAllProperties()
    {
        var teacherId = Guid.NewGuid();
        var studentId = Guid.NewGuid();
        var structureId = Guid.NewGuid();
        var scheduledAt = new DateTime(2026, 10, 12, 15, 30, 0);

        var meeting = new Meeting(teacherId, studentId, structureId, scheduledAt, 30);

        Assert.NotEqual(Guid.Empty, meeting.Id);
        Assert.Equal(teacherId, meeting.TeacherRefId);
        Assert.Equal(studentId, meeting.StudentRefId);
        Assert.Equal(structureId, meeting.StructureRefId);
        Assert.Equal(scheduledAt, meeting.ScheduledAt);
        Assert.Equal(30, meeting.DurationMinutes);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-15)]
    public void Constructor_WhenDurationIsNotPositive_ThrowsArgumentException(int durationMinutes)
    {
        var exception = Assert.Throws<ArgumentException>(() =>
            new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, durationMinutes));

        Assert.Equal("durationMinutes", exception.ParamName);
    }

    [Fact]
    public void EndsAt_AddsDurationToStart()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, new DateTime(2026, 10, 12, 10, 0, 0), 45);

        Assert.Equal(new DateTime(2026, 10, 12, 10, 45, 0), meeting.EndsAt);
    }

    [Fact]
    public void Constructor_StartsInPendingStatus()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);

        Assert.Equal(MeetingStatus.Pending, meeting.Status);
    }

    [Fact]
    public void Constructor_WithoutStructure_AllowsNullStructure()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);

        Assert.Null(meeting.StructureRefId);
    }

    [Fact]
    public void Confirm_WhenPending_SetsConfirmedStatus()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);

        meeting.Confirm();

        Assert.Equal(MeetingStatus.Confirmed, meeting.Status);
    }

    [Fact]
    public void Confirm_WhenAlreadyConfirmed_ThrowsInvalidOperationException()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);
        meeting.Confirm();

        var exception = Assert.Throws<InvalidOperationException>(meeting.Confirm);

        Assert.Equal("Only a pending meeting can be confirmed.", exception.Message);
    }

    [Fact]
    public void Complete_WhenConfirmed_SetsCompletedStatus()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);
        meeting.Confirm();

        meeting.Complete();

        Assert.Equal(MeetingStatus.Completed, meeting.Status);
    }

    [Fact]
    public void Complete_WhenPending_ThrowsInvalidOperationException()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);

        var exception = Assert.Throws<InvalidOperationException>(meeting.Complete);

        Assert.Equal("Only a confirmed meeting can be completed.", exception.Message);
    }

    [Fact]
    public void Cancel_WhenConfirmed_SetsCancelledStatus()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);
        meeting.Confirm();

        meeting.Cancel();

        Assert.Equal(MeetingStatus.Cancelled, meeting.Status);
    }

    [Fact]
    public void Cancel_WhenPending_SetsCancelledStatus()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);

        meeting.Cancel();

        Assert.Equal(MeetingStatus.Cancelled, meeting.Status);
    }

    [Fact]
    public void Cancel_WhenAlreadyCancelled_ThrowsInvalidOperationException()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);
        meeting.Cancel();

        var exception = Assert.Throws<InvalidOperationException>(meeting.Cancel);

        Assert.Equal("A cancelled meeting cannot be cancelled.", exception.Message);
    }

    [Fact]
    public void Cancel_WhenCompleted_ThrowsInvalidOperationException()
    {
        var meeting = new Meeting(Guid.NewGuid(), Guid.NewGuid(), null, DateTime.Today, 45);
        meeting.Confirm();
        meeting.Complete();

        var exception = Assert.Throws<InvalidOperationException>(meeting.Cancel);

        Assert.Equal("A completed meeting cannot be cancelled.", exception.Message);
    }
}
