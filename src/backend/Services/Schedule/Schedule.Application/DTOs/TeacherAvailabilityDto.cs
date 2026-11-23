using System;
using System.Collections.Generic;

namespace Schedule.Application.DTOs;

public record TeacherAvailabilityDto(
    Guid TeacherRefId,
    IReadOnlyList<OfficeHourDto> AvailableBlocks);
