using System;

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
    string Name,
    string Address,
    double Latitude,
    double Longitude,
    decimal Zoom = 0m,
    decimal Pitch = 0m,
    decimal Bearing = 0m
);

public record UpdateCampusDto(
    string Name,
    string Address,
    double Latitude,
    double Longitude,
    decimal Zoom = 0m,
    decimal Pitch = 0m,
    decimal Bearing = 0m
);
