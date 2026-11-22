using System;

namespace Schedule.Application.DTOs;

public record UpdateOfficeHourRequest(
    Guid? StructureRefId,
    DayOfWeek DayOfWeek,
    TimeOnly StartTime,
    TimeOnly EndTime);
