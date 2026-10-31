using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record BuildingDto(
    Guid Id,
    Guid CampusId,
    string Name,
    int FloorsCount,
    double Latitude,
    double Longitude,
    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,
    string? Services = null
);

public record CreateBuildingDto(
    [Required(ErrorMessage = "CampusId is required.")]
    Guid CampusId,

    [Required(ErrorMessage = "Name is required.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Range(1, int.MaxValue, ErrorMessage = "FloorsCount must be at least 1.")]
    int FloorsCount,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude,

    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,

    [MaxLength(150, ErrorMessage = "Services cannot exceed 150 characters.")]
    string? Services = null
);

public record UpdateBuildingDto(
    [Required(ErrorMessage = "CampusId is required.")]
    Guid CampusId,

    [Required(ErrorMessage = "Name is required.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Range(1, int.MaxValue, ErrorMessage = "FloorsCount must be at least 1.")]
    int FloorsCount,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude,

    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,

    [MaxLength(150, ErrorMessage = "Services cannot exceed 150 characters.")]
    string? Services = null
);

public record LocationDto(
    double Latitude,
    double Longitude
);

public record UpdateLocationDto(
    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude
);

public record BuildingMetadataDto(
    Guid CampusId,
    int FloorsCount,
    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,
    string? Services = null
);

public record BuildingLocationDto(
    Guid Id,
    string Name,
    LocationDto Location,
    BuildingMetadataDto Metadata
);
