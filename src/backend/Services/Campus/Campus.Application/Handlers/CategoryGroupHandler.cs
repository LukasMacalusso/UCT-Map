using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Application.DTOs;

namespace Campus.Application.Handlers;

public class CategoryGroupHandler
{
    private readonly IGenericRepository<CategoryGroup> _repository;

    public CategoryGroupHandler(IGenericRepository<CategoryGroup> repository)
    {
        _repository = repository;
    }

    public async Task<IEnumerable<CategoryGroupDto>> GetAllAsync(CancellationToken cancellationToken)
    {
        var groups = await _repository.GetAllAsync(null, cancellationToken);
        return groups.OrderBy(g => g.Order).Select(g => new CategoryGroupDto(g.Id, g.Name, g.Order));
    }

    public async Task<CategoryGroupDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return null;
        return new CategoryGroupDto(group.Id, group.Name, group.Order);
    }

    public async Task<CategoryGroupDto> CreateAsync(CreateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        var group = new CategoryGroup(request.Name, request.Order);
        await _repository.AddAsync(group, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);
        return new CategoryGroupDto(group.Id, group.Name, group.Order);
    }

    public async Task<bool> UpdateAsync(Guid id, UpdateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return false;

        group.Update(request.Name, request.Order);
        _repository.Update(group);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<(bool success, string? error, bool notFound)> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return (false, null, true);

        try
        {
            _repository.Delete(group);
            await _repository.SaveChangesAsync(cancellationToken);
            return (true, null, false);
        }
        catch (Exception ex) when (ex.GetType().Name == "DbUpdateException")
        {
            return (false, "Cannot delete category group due to existing database constraints.", false);
        }
    }

    public async Task<bool> ReorderAsync(IEnumerable<ReorderItemDto> items, CancellationToken cancellationToken)
    {
        var itemsList = items?.ToList() ?? new List<ReorderItemDto>();
        if (itemsList.Count == 0) return true;

        var ids = itemsList.Select(i => i.Id).Distinct().ToHashSet();
        var groups = (await _repository.GetAllAsync(g => ids.Contains(g.Id), cancellationToken)).ToDictionary(g => g.Id);

        if (groups.Count != ids.Count)
        {
            return false;
        }

        foreach (var item in itemsList)
        {
            if (groups.TryGetValue(item.Id, out var group))
            {
                group.UpdateOrder(item.Order);
                _repository.Update(group);
            }
        }

        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
