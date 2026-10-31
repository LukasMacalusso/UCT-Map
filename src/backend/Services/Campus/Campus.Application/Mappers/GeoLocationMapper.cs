using System;
using System.Globalization;
using System.Linq;
using Campus.Application.DTOs;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.Application.Mappers;

public static class GeoLocationMapper
{
    public static LocationDto ToLocationDto(this Coordinate coordinate) =>
        new(coordinate.Latitude, coordinate.Longitude);

    public static CampusDto ToDto(this CampusEntity campus) =>
        new(
            campus.Id,
            campus.Name,
            campus.Address,
            campus.Coordinates.Latitude,
            campus.Coordinates.Longitude,
            campus.Zoom,
            campus.Pitch,
            campus.Bearing
        );

    public static BuildingDto ToDto(this Building building) =>
        new(
            building.Id,
            building.CampusId,
            building.Name,
            building.FloorsCount,
            building.Coordinates.Latitude,
            building.Coordinates.Longitude,
            building.OpenTime,
            building.CloseTime,
            building.Services
        );

    public static StructureDto ToDto(this Structure structure) =>
        new(
            structure.Id,
            structure.CampusId,
            structure.CategoryId,
            structure.Name,
            structure.Coordinates.Latitude,
            structure.Coordinates.Longitude
        );

    public static BuildingLocationDto ToLocationDto(this Building building) =>
        new(
            building.Id,
            building.Name,
            building.Coordinates.ToLocationDto(),
            new BuildingMetadataDto(
                building.CampusId,
                building.FloorsCount,
                FormatSchedule(building.OpenTime, building.CloseTime),
                ParseServices(building.Services)
            )
        );

    public static StructureLocationDto ToLocationDto(this Structure structure, string categoryName, string categoryIcon) =>
        new(
            structure.Id,
            structure.Name,
            structure.Coordinates.ToLocationDto(),
            new StructureMetadataDto(
                structure.CampusId,
                structure.CategoryId,
                categoryName,
                categoryIcon
            )
        );

    public static CampusMapDto ToMapDto(this CampusEntity campus) =>
        new(
            campus.Id,
            campus.Name,
            campus.Address,
            new MapCameraDto(
                campus.Coordinates.ToLocationDto(),
                campus.Zoom,
                campus.Pitch,
                campus.Bearing
            ),
            campus.Buildings.Select(b => b.ToLocationDto()).ToArray(),
            campus.Structures.Select(s => s.ToLocationDto(
                s.Category?.Name ?? string.Empty,
                s.Category?.Icon ?? string.Empty
            )).ToArray()
        );

    private static string? FormatSchedule(TimeOnly? openTime, TimeOnly? closeTime) =>
        (openTime, closeTime) switch
        {
            ({ } open, { } close) => string.Create(CultureInfo.InvariantCulture, $"{open:HH:mm} - {close:HH:mm}"),
            ({ } open, null) => open.ToString("HH:mm", CultureInfo.InvariantCulture),
            (null, { } close) => close.ToString("HH:mm", CultureInfo.InvariantCulture),
            _ => null
        };

    private static string[] ParseServices(string? services) =>
        string.IsNullOrWhiteSpace(services)
            ? Array.Empty<string>()
            : services.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
}
