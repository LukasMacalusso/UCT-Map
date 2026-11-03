using System;
using System.Collections.Generic;
using Campus.Domain.ValueObjects;

namespace Campus.Domain.Entities;

public class Building
{
    public Guid Id { get; private set; }
    public Guid CampusId { get; private set; }
    public Guid? CategoryId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public int FloorsCount { get; private set; }
    public TimeOnly? OpenTime { get; private set; }
    public TimeOnly? CloseTime { get; private set; }
    public string? Services { get; private set; }

    public Coordinate Coordinates { get; private set; } = null!;

    public Campus Campus { get; private set; } = null!;
    public Category? Category { get; private set; }
    public ICollection<Room> Rooms { get; private set; } = new List<Room>();

    public Building(string name, int floorsCount, Coordinate coordinates, Campus campus, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null, Guid? categoryId = null)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.OpenTime = openTime;
        this.CloseTime = closeTime;
        this.Services = services;
        this.CategoryId = categoryId;

        this.Campus = campus;
        this.CampusId = campus.Id;
    }

    public Building(string name, int floorsCount, Coordinate coordinates, Campus campus, Category? category, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null)
        : this(name, floorsCount, coordinates, campus, openTime, closeTime, services, category?.Id)
    {
        this.Category = category;
    }

    public Building(string name, int floorsCount, Coordinate coordinates, Guid campusId, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null, Guid? categoryId = null)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.OpenTime = openTime;
        this.CloseTime = closeTime;
        this.Services = services;
        this.CategoryId = categoryId;
    }

    public Building(string name, int floorsCount, Coordinate coordinates, Guid campusId, Guid? categoryId, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null)
        : this(name, floorsCount, coordinates, campusId, openTime, closeTime, services, categoryId)
    {
    }

    public void Update(string name, int floorsCount, Coordinate coordinates, Guid campusId, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null, Guid? categoryId = null)
    {
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.OpenTime = openTime;
        this.CloseTime = closeTime;
        this.Services = services;
        this.CategoryId = categoryId;
    }

    public void Update(string name, int floorsCount, Coordinate coordinates, Guid campusId, Guid? categoryId, TimeOnly? openTime = null, TimeOnly? closeTime = null, string? services = null)
    {
        Update(name, floorsCount, coordinates, campusId, openTime, closeTime, services, categoryId);
    }

    public void AssignCategory(Guid? categoryId)
    {
        this.CategoryId = categoryId;
    }

    public void UpdateLocation(Coordinate coordinates)
    {
        this.Coordinates = coordinates;
    }

    protected Building() { }
}
