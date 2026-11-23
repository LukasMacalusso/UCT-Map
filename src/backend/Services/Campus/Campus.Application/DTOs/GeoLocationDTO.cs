using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

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

public record MapCameraDto(
    LocationDto Center,
    decimal Zoom,
    decimal Pitch,
    decimal Bearing
);

public record CampusMapDto(
    Guid Id,
    string Name,
    string Address,
    MapCameraDto Camera,
    IReadOnlyList<BuildingLocationDto> Buildings,
    IReadOnlyList<StructureLocationDto> Structures
);
