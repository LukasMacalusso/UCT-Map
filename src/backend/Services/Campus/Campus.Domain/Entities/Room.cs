using System;

namespace Campus.Domain.Entities;

public class Room
{
    public Guid Id { get; private set; }
    public Guid BuildingId { get; private set; }
    public Guid CategoryId { get; private set; }

    public string Name { get; private set; } = string.Empty;
    public int Floor { get; private set; }
    public string? Number { get; private set; }

    public Building Building { get; private set; } = null!;
    public Category Category { get; private set; } = null!;

    public Room(string name, int floor, string? number, Building building, Category category)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Floor = floor;
        this.Number = number;

        this.Building = building;
        this.BuildingId = building.Id;

        this.Category = category;
        this.CategoryId = category.Id;
    }

    public Room(string name, int floor, string? number, Guid buildingId, Guid categoryId)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Floor = floor;
        this.Number = number;
        this.BuildingId = buildingId;
        this.CategoryId = categoryId;
    }

    public void Update(string name, int floor, string? number, Guid buildingId, Guid categoryId)
    {
        this.Name = name;
        this.Floor = floor;
        this.Number = number;
        this.BuildingId = buildingId;
        this.CategoryId = categoryId;
    }

    protected Room() { }
}
