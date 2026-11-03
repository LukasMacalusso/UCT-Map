using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.Domain.Entities;
using Campus.Domain.Interfaces;
using ErrorOr;

namespace Campus.Application.Handlers;

public class CategoryHandler
{
    private readonly IGenericRepository<Category> _repository;

    public CategoryHandler(IGenericRepository<Category> repository)
    {
        _repository = repository;
    }

    public async Task<IEnumerable<CategoryDto>> GetAllAsync(CancellationToken cancellationToken)
    {
        var categories = await _repository.GetAllAsync(null, cancellationToken);
        return categories.OrderBy(c => c.Order).Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Description, c.Order));
    }

    public async Task<ErrorOr<CategoryDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return Error.NotFound("Category.NotFound", $"Category with ID '{id}' was not found.");

        return new CategoryDto(category.Id, category.Name, category.Icon, category.Description, category.Order);
    }

    public async Task<ErrorOr<CategoryDto>> CreateAsync(CreateCategoryDto request, CancellationToken cancellationToken)
    {
        var category = new Category(request.Name, request.Icon, request.Description, request.Order);
        await _repository.AddAsync(category, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        return new CategoryDto(category.Id, category.Name, category.Icon, category.Description, category.Order);
    }

    public async Task<ErrorOr<Success>> UpdateAsync(Guid id, UpdateCategoryDto request, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return Error.NotFound("Category.NotFound", $"Category with ID '{id}' was not found.");

        category.Update(request.Name, request.Icon, request.Description, request.Order);
        _repository.Update(category);
        await _repository.SaveChangesAsync(cancellationToken);

        return Result.Success;
    }

    public async Task<ErrorOr<Success>> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return Error.NotFound("Category.NotFound", $"Category with ID '{id}' was not found.");

        try
        {
            _repository.Delete(category);
            await _repository.SaveChangesAsync(cancellationToken);
            return Result.Success;
        }
        catch (Exception ex) when (ex.GetType().Name == "DbUpdateException")
        {
            return Error.Conflict("Category.Conflict", "Cannot delete category due to existing database constraints.");
        }
    }

    public async Task<ErrorOr<Success>> ReorderAsync(IEnumerable<ReorderItemDto> items, CancellationToken cancellationToken)
    {
        var itemsList = items?.ToList() ?? new List<ReorderItemDto>();
        if (itemsList.Count == 0) return Result.Success;

        var ids = itemsList.Select(i => i.Id).Distinct().ToHashSet();
        var categories = (await _repository.GetAllAsync(c => ids.Contains(c.Id), cancellationToken)).ToDictionary(c => c.Id);

        if (categories.Count != ids.Count) return Error.Validation("Category.ReorderInvalid", "Failed to reorder categories. Some items may not exist.");

        foreach (var item in itemsList)
        {
            if (categories.TryGetValue(item.Id, out var category))
            {
                category.UpdateOrder(item.Order);
                _repository.Update(category);
            }
        }

        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }
}
