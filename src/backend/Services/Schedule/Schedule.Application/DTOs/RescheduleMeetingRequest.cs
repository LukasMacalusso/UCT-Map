using System;

namespace Schedule.Application.DTOs;

public record RescheduleMeetingRequest(
    Guid? StructureRefId,
    DateTime ScheduledAt,
    int DurationMinutes);
