using System;
using System.Collections.Generic;

namespace Campus.Domain.Entities;

public class CategoryGroup
{
    public Guid Id { get; private set; }
    public string Name { get; private set; } = string.Empty;
    public int Order { get; private set; }

    public ICollection<Category> Categories { get; private set; } = new List<Category>();

    public CategoryGroup(string name, int order = 0)
    {
        this.Id = Guid.NewGuid();
        this.Name = name;
        this.Order = order;
    }

    public void Update(string name, int order)
    {
        this.Name = name;
        this.Order = order;
    }

    public void Update(string name)
    {
        this.Name = name;
    }

    public void UpdateOrder(int order)
    {
        this.Order = order;
    }

    protected CategoryGroup() { }
}
