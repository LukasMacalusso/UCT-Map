using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record StructureDto(
    Guid Id,
    Guid CampusId,
    Guid CategoryId,
    string Name,
    double Latitude,
    double Longitude
);

public record CreateStructureDto(
    [Required(ErrorMessage = "CampusId is required.")]
    Guid CampusId,

    [Required(ErrorMessage = "CategoryId is required.")]
    Guid CategoryId,

    [Required(ErrorMessage = "Name is Required.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude
);

public record UpdateStructureDto(
    [Required(ErrorMessage = "CampusId is required.")]
    Guid CampusId,

    [Required(ErrorMessage = "CategoryId is required.")]
    Guid CategoryId,

    [Required(ErrorMessage = "Name is Required.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Range(-90.0, 90.0, ErrorMessage = "Latitude must be between -90 and 90.")]
    double Latitude,

    [Range(-180.0, 180.0, ErrorMessage = "Longitude must be between -180 and 180.")]
    double Longitude
);

public record StructureMetadataDto(
    Guid CampusId,
    Guid CategoryId,
    string CategoryName
);

public record StructureLocationDto(
    Guid Id,
    string Name,
    LocationDto Location,
    StructureMetadataDto Metadata
);
