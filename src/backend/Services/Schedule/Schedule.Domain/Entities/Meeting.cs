using System;
using Schedule.Domain.Enums;

namespace Schedule.Domain.Entities;

public class Meeting
{
    public Guid Id { get; private set; }
    public Guid TeacherRefId { get; private set; }
    public Guid StudentRefId { get; private set; }
    public Guid? StructureRefId { get; private set; }
    public DateTime ScheduledAt { get; private set; }
    public int DurationMinutes { get; private set; }
    public MeetingStatus Status { get; private set; }

    public DateTime EndsAt => ScheduledAt.AddMinutes(DurationMinutes);

    public Meeting(
        Guid teacherRefId,
        Guid studentRefId,
        Guid? structureRefId,
        DateTime scheduledAt,
        int durationMinutes)
    {
        if (durationMinutes <= 0)
        {
            throw new ArgumentException(
                "Duration must be greater than zero minutes", nameof(durationMinutes));
        }

        this.Id = Guid.NewGuid();
        this.TeacherRefId = teacherRefId;
        this.StudentRefId = studentRefId;
        this.StructureRefId = structureRefId;
        this.ScheduledAt = scheduledAt;
        this.DurationMinutes = durationMinutes;
        this.Status = MeetingStatus.Pending;
    }

    public void Cancel()
    {
        if (this.Status is MeetingStatus.Cancelled or MeetingStatus.Completed)
        {
            throw new InvalidOperationException(
                $"A {this.Status.ToString().ToLowerInvariant()} meeting cannot be cancelled.");
        }

        this.Status = MeetingStatus.Cancelled;
    }

    protected Meeting() { }
}

