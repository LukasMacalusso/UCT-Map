using System;

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
    Guid CampusId,
    string Name,
    int FloorsCount,
    double Latitude,
    double Longitude,
    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,
    string? Services = null
);

public record UpdateBuildingDto(
    Guid CampusId,
    string Name,
    int FloorsCount,
    double Latitude,
    double Longitude,
    TimeOnly? OpenTime = null,
    TimeOnly? CloseTime = null,
    string? Services = null
);

public record LocationDto(
    double Latitude,
    double Longitude
);

public record UpdateLocationDto(
    double Latitude,
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
