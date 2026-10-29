using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Application.DTOs;

namespace Campus.Application.Handlers;

public class CategoryHandler
{
    private readonly IGenericRepository<Category> _repository;
    private readonly IGenericRepository<CategoryGroup> _categoryGroupRepository;

    public CategoryHandler(IGenericRepository<Category> repository, IGenericRepository<CategoryGroup> categoryGroupRepository)
    {
        _repository = repository;
        _categoryGroupRepository = categoryGroupRepository;
    }

    public async Task<IEnumerable<CategoryDto>> GetAllAsync(CancellationToken cancellationToken)
    {
        var categories = await _repository.GetAllAsync(null, cancellationToken);
        return categories.Select(c => new CategoryDto(c.Id, c.CategoryGroupId, c.Name, c.Icon, c.Description));
    }

    public async Task<CategoryDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return null;
        return new CategoryDto(category.Id, category.CategoryGroupId, category.Name, category.Icon, category.Description);
    }

    public async Task<(CategoryDto? dto, string? error)> CreateAsync(CreateCategoryDto request, CancellationToken cancellationToken)
    {
        if (!await _categoryGroupRepository.ExistsAsync(cg => cg.Id == request.CategoryGroupId, cancellationToken))
            return (null, $"CategoryGroup with ID '{request.CategoryGroupId}' does not exist.");

        var category = new Category(request.Name, request.Icon, request.Description, request.CategoryGroupId);
        await _repository.AddAsync(category, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);
        return (new CategoryDto(category.Id, category.CategoryGroupId, category.Name, category.Icon, category.Description), null);
    }

    public async Task<(bool success, string? error)> UpdateAsync(Guid id, UpdateCategoryDto request, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return (false, null);

        if (!await _categoryGroupRepository.ExistsAsync(cg => cg.Id == request.CategoryGroupId, cancellationToken))
            return (false, $"CategoryGroup with ID '{request.CategoryGroupId}' does not exist.");

        category.Update(request.Name, request.Icon, request.Description, request.CategoryGroupId);
        _repository.Update(category);
        await _repository.SaveChangesAsync(cancellationToken);
        return (true, null);
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var category = await _repository.GetByIdAsync(id, cancellationToken);
        if (category == null) return false;

        _repository.Delete(category);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
