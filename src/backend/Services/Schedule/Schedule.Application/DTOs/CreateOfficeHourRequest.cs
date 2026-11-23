using System;

namespace Schedule.Application.DTOs;

public record CreateOfficeHourRequest(
    Guid TeacherRefId,
    Guid? StructureRefId,
    DayOfWeek DayOfWeek,
    TimeOnly StartTime,
    TimeOnly EndTime);

