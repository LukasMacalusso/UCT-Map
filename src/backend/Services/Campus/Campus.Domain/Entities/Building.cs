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

    public Coordinate Coordinates { get; private set; } = null!;

    public Campus Campus { get; private set; } = null!;
    public ICollection<Room> Rooms { get; private set; } = new List<Room>();

    public Building(string name, int floorsCount, Coordinate coordinates, Campus campus)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;

        this.Campus = campus;
        this.CampusId = campus.Id;
    }

    public Building(string name, int floorsCount, Coordinate coordinates, Guid campusId)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
    }

    public void Update(string name, int floorsCount, Coordinate coordinates, Guid campusId)
    {
        this.Name = name;
        this.FloorsCount = floorsCount;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
    }

    protected Building() { }
}
