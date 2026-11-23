using System;
using System.Collections.Generic;

namespace Schedule.Application.DTOs;

public record StudentMeetingsDto(
    Guid StudentRefId,
    DateTime From,
    DateTime To,
    int MeetingCount,
    IReadOnlyList<MeetingDto> Meetings);

