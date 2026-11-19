using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record BuildingDto(
    Guid Id,
    Guid CampusId,
    string Name,
    int FloorsCount,
    double Latitude,
    double Longitude,
    Guid? CategoryId = null,
    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,
    string? Services = null,
    string? PhotoUrl = null,
    string? CategoryName = null,
    string? CategoryIcon = null
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
    string? Services = null,

    Guid? CategoryId = null,

    [MaxLength(500, ErrorMessage = "PhotoUrl cannot exceed 500 characters.")]
    string? PhotoUrl = null
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
    string? Services = null,

    Guid? CategoryId = null,

    [MaxLength(500, ErrorMessage = "PhotoUrl cannot exceed 500 characters.")]
    string? PhotoUrl = null
);

public record BuildingMetadataDto(
    Guid CampusId,
    int FloorsCount,
    string? Schedule,
    IReadOnlyList<string> Services,
    Guid? CategoryId = null,
    string? PhotoUrl = null,
    string CategoryName = "",
    string CategoryIcon = ""
);

public record BuildingLocationDto(
    Guid Id,
    string Name,
    LocationDto Location,
    BuildingMetadataDto Metadata,
    Guid? CategoryId = null
);
