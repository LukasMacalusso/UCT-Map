using System;
using System.Collections.Generic;

namespace Schedule.Application.DTOs;

public record TeacherWorkloadDto(
    Guid TeacherRefId,
    DateTime From,
    DateTime To,
    int WeeklyOfficeHourMinutes,
    int MeetingCount,
    IReadOnlyList<OfficeHourDto> OfficeHours,
    IReadOnlyList<MeetingDto> Meetings);
