using System;
using System.Collections.Generic;

namespace Campus.Domain.Entities;

public class CategoryGroup
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;

    public ICollection<Category> Categories { get; private set; } = new List<Category>();

    public CategoryGroup(string name)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
    }

    public void Update(string name)
    {
        this.Name = name;
    }

    protected CategoryGroup() { }
}
