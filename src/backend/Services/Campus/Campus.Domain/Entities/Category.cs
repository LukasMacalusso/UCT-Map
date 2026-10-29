using System;
using System.Collections.Generic;

namespace Campus.Domain.Entities;

public class Category
{
    public Guid Id { get; private set; }
    public Guid CategoryGroupId { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public string Icon { get; private set; } = string.Empty;
    public string? Description { get; private set; }

    public CategoryGroup CategoryGroup { get; private set; } = null!;
    public ICollection<Room> Rooms { get; private set; } = new List<Room>();
    public ICollection<Structure> Structures { get; private set; } = new List<Structure>();

    public Category(string name, string icon, string? description, CategoryGroup categoryGroup)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Icon = icon;
        this.Description = description;
        this.CategoryGroup = categoryGroup;
        this.CategoryGroupId = categoryGroup.Id;
    }

    public Category(string name, string icon, string? description, Guid categoryGroupId)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Icon = icon;
        this.Description = description;
        this.CategoryGroupId = categoryGroupId;
    }

    public void Update(string name, string icon, string? description, Guid categoryGroupId)
    {
        this.Name = name;
        this.Icon = icon;
        this.Description = description;
        this.CategoryGroupId = categoryGroupId;
    }

    protected Category() { }
}
