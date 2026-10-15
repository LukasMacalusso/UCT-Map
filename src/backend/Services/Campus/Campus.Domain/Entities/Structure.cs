using System;
using Campus.Domain.ValueObjects;

namespace Campus.Domain.Entities;

public class Structure
{
    public Guid Id { get; private set; }
    public Guid CampusId { get; private set; }
    public Guid CategoryId { get; private set; }

    public string Name { get; private set; } = string.Empty;

    public Coordinate Coordinates { get; private set; } = null!;

    public Campus Campus { get; private set; } = null!;
    public Category Category { get; private set; } = null!;

    public Structure(string name, Coordinate coordinates, Campus campus, Category category)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Coordinates = coordinates;

        this.Campus = campus;
        this.CampusId = campus.Id;

        this.Category = category;
        this.CategoryId = category.Id;
    }

    public Structure(string name, Coordinate coordinates, Guid campusId, Guid categoryId)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.CategoryId = categoryId;
    }

    public void Update(string name, Coordinate coordinates, Guid campusId, Guid categoryId)
    {
        this.Name = name;
        this.Coordinates = coordinates;
        this.CampusId = campusId;
        this.CategoryId = categoryId;
    }

    public void UpdateLocation(Coordinate coordinates)
    {
        this.Coordinates = coordinates;
    }

    protected Structure() { }
}
