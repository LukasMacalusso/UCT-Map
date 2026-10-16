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

    public ICollection<Building> Buildings { get; private set; } = new List<Building>();
    public ICollection<Structure> Structures { get; private set; } = new List<Structure>();

    public Campus(string name, string address, Coordinate coordinates)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Address = address;
        this.Coordinates = coordinates;
    }

    public void Update(string name, string address, Coordinate coordinates)
    {
        this.Name = name;
        this.Address = address;
        this.Coordinates = coordinates;
    }

    public void UpdateLocation(Coordinate coordinates)
    {
        this.Coordinates = coordinates;
    }

    protected Campus() { }
}
