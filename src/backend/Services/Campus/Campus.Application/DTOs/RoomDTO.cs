using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record RoomDto(
    Guid Id,
    Guid BuildingId,
    Guid CategoryId,
    string Name,
    int Floor
);

public record CreateRoomDto(
    [Required(ErrorMessage = "BuildingId is required.")]
    Guid BuildingId,

    [Required(ErrorMessage = "CategoryId is required.")]
    Guid CategoryId,

    [Required(ErrorMessage = "Name is required.")]
    [StringLength(20, ErrorMessage = "Room name cannot exceed 20 characters.")]
    string Name,

    [Range(1, int.MaxValue, ErrorMessage = "Floor must be at least 1.")]
    int Floor
);

public record UpdateRoomDto(
    [Required(ErrorMessage = "BuildingId is required.")]
    Guid BuildingId,

    [Required(ErrorMessage = "CategoryId is required.")]
    Guid CategoryId,

    [Required(ErrorMessage = "Name is required.")]
    [StringLength(20, ErrorMessage = "Room name cannot exceed 20 characters.")]
    string Name,

    [Range(1, int.MaxValue, ErrorMessage = "Floor must be at least 1.")]
    int Floor
);
