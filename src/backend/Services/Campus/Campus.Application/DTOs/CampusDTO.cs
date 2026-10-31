using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record CampusDto(
    Guid Id,
    string Name,
    string Address,
    double Latitude,
    double Longitude,
    decimal Zoom = 0m,
    decimal Pitch = 0m,
    decimal Bearing = 0m
);

public record CreateCampusDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Address is mandatory.")]
    [StringLength(100, ErrorMessage = "Address cannot exceed 100 characters.")]
    string Address,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude,

    [Range(0, 22, ErrorMessage = "Zoom must be between 0 and 22.")]
    decimal Zoom = 0m,

    [Range(0, 85, ErrorMessage = "Pitch must be between 0 and 85.")]
    decimal Pitch = 0m,

    [Range(-180, 180, ErrorMessage = "Bearing must be between -180 and 180.")]
    decimal Bearing = 0m
);

public record UpdateCampusDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Address is mandatory.")]
    [StringLength(100, ErrorMessage = "Address cannot exceed 100 characters.")]
    string Address,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude,

    [Range(0, 22, ErrorMessage = "Zoom must be between 0 and 22.")]
    decimal Zoom = 0m,

    [Range(0, 85, ErrorMessage = "Pitch must be between 0 and 85.")]
    decimal Pitch = 0m,

    [Range(-180, 180, ErrorMessage = "Bearing must be between -180 and 180.")]
    decimal Bearing = 0m
);
