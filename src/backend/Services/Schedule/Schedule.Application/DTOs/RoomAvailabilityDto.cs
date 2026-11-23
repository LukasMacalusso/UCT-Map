using System;
using System.Collections.Generic;

namespace Schedule.Application.DTOs;

public record RoomAvailabilityDto(
    DateTime From,
    DateTime To,
    IReadOnlyList<Guid> FreeRoomIds,
    IReadOnlyList<RoomOccupancyDto> Occupancies);
