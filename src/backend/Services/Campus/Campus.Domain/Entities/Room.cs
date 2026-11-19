using System;

namespace Campus.Domain.Entities;

public class Room
{
    public Guid Id { get; private set; }
    public Guid BuildingId { get; private set; }

    public string Name { get; private set; } = string.Empty;
    public int Floor { get; private set; }

    public Building Building { get; private set; } = null!;

    public Room(string name, int floor, Building building)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Floor = floor;

        this.Building = building;
        this.BuildingId = building.Id;


    }

    public Room(string name, int floor, Guid buildingId)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Floor = floor;
        this.BuildingId = buildingId;

    }

    public void Update(string name, int floor, Guid buildingId)
    {
        this.Name = name;
        this.Floor = floor;
        this.BuildingId = buildingId;

    }
    protected Room() { }
}
