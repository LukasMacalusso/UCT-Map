using System;
using System.Collections.Generic;
using Campus.Domain.ValueObjects;

namespace Campus.Domain.Entities;

public class Building
{
    public Guid Id { get; private set; }
    public Guid CampusId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public int FloorsCount { get; private set; }
    public string Schedule { get; private set; } = string.Empty;
    public List<string> Services { get; private set; } = new();

    public Coordinate Coordinates { get; private set; } = null!;

    public Campus Campus { get; private set; } = null!;
    public ICollection<Room> Rooms { get; private set; } = new List<Room>();

    public Building(string name, int floorsCount, Coordinate coordinates, Campus campus, string schedule = "", List<string>? services = null)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.Schedule = schedule ?? string.Empty;
        this.Services = services ?? new List<string>();

        this.Campus = campus;
        this.CampusId = campus.Id;
    }

    public Building(string name, int floorsCount, Coordinate coordinates, Guid campusId, string schedule = "", List<string>? services = null)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.Schedule = schedule ?? string.Empty;
        this.Services = services ?? new List<string>();
    }

    public void Update(string name, int floorsCount, Coordinate coordinates, Guid campusId, string schedule = "", List<string>? services = null)
    {
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.Schedule = schedule ?? string.Empty;
        this.Services = services ?? new List<string>();
    }

    public void UpdateLocation(Coordinate coordinates)
    {
        this.Coordinates = coordinates;
    }

    protected Building() { }
}
