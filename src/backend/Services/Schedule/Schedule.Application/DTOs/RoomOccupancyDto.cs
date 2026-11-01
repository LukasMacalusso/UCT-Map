using System;

namespace Schedule.Application.DTOs;

public record RoomOccupancyDto(
    Guid StructureRefId,
    string Reason,
    DateTime OccupiedFrom,
    DateTime OccupiedUntil);
