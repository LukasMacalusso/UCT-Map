using System;
using System.Collections.Generic;
using Campus.Domain.ValueObjects;

namespace Campus.Domain.Entities;

public class Campus
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Address { get; private set; } = string.Empty;

    public Coordinate Coordinates { get; private set; } = null!;
    public decimal Zoom { get; private set; }
    public decimal Pitch { get; private set; }
    public decimal Bearing { get; private set; }

    public ICollection<Building> Buildings { get; private set; } = new List<Building>();
    public ICollection<Structure> Structures { get; private set; } = new List<Structure>();

    public Campus(string name, string address, Coordinate coordinates, decimal zoom = 0m, decimal pitch = 0m, decimal bearing = 0m)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Address = address;
        this.Coordinates = coordinates;
        this.Zoom = zoom;
        this.Pitch = pitch;
        this.Bearing = bearing;
    }

    public void Update(string name, string address, Coordinate coordinates, decimal zoom = 0m, decimal pitch = 0m, decimal bearing = 0m)
    {
        this.Name = name;
        this.Address = address;
        this.Coordinates = coordinates;
        this.Zoom = zoom;
        this.Pitch = pitch;
        this.Bearing = bearing;
    }

    public void UpdateLocation(Coordinate coordinates)
    {
        this.Coordinates = coordinates;
    }

    protected Campus() { }
}
