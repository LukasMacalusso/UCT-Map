using System;

namespace Schedule.Application.DTOs;

public record CreateMeetingRequest(
    Guid TeacherRefId,
    Guid StudentRefId,
    Guid? StructureRefId,
    DateTime ScheduledAt,
    int DurationMinutes);

