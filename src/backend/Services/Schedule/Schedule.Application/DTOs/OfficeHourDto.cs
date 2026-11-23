using System;
using Schedule.Domain.Entities;

namespace Schedule.Application.DTOs;

public record OfficeHourDto(
    Guid Id,
    Guid TeacherRefId,
    Guid? StructureRefId,
    string DayOfWeek,
    TimeOnly StartTime,
    TimeOnly EndTime)
{
    public static OfficeHourDto FromEntity(OfficeHour officeHour) => new(
        officeHour.Id,
        officeHour.TeacherRefId,
        officeHour.StructureRefId,
        officeHour.DayOfWeek.ToString(),
        officeHour.StartTime,
        officeHour.EndTime);
}

