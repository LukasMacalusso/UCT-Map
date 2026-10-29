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
        return groups.Select(g => new CategoryGroupDto(g.Id, g.Name));
    }

    public async Task<CategoryGroupDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return null;
        return new CategoryGroupDto(group.Id, group.Name);
    }

    public async Task<CategoryGroupDto> CreateAsync(CreateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        var group = new CategoryGroup(request.Name);
        await _repository.AddAsync(group, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);
        return new CategoryGroupDto(group.Id, group.Name);
    }

    public async Task<bool> UpdateAsync(Guid id, UpdateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return false;

        group.Update(request.Name);
        _repository.Update(group);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var group = await _repository.GetByIdAsync(id, cancellationToken);
        if (group == null) return false;

        _repository.Delete(group);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
