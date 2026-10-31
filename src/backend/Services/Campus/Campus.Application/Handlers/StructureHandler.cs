using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Campus.Application.DTOs;
using Campus.Application.Mappers;

namespace Campus.Application.Handlers;

public class StructureHandler
{
    private readonly IGenericRepository<Structure> _repository;
    private readonly IGenericRepository<Campus.Domain.Entities.Campus> _campusRepository;
    private readonly IGenericRepository<Category> _categoryRepository;

    public StructureHandler(IGenericRepository<Structure> repository, IGenericRepository<Campus.Domain.Entities.Campus> campusRepository, IGenericRepository<Category> categoryRepository)
    {
        _repository = repository;
        _campusRepository = campusRepository;
        _categoryRepository = categoryRepository;
    }

    public async Task<IEnumerable<StructureDto>> GetAllAsync(Guid? campusId, Guid? categoryId, CancellationToken cancellationToken)
    {
        var structures = await _repository.GetAllAsync(BuildFilterPredicate(campusId, categoryId), cancellationToken);
        return structures.Select(s => s.ToDto());
    }

    public async Task<StructureDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        return structure?.ToDto();
    }

    public async Task<(StructureDto? dto, string? error)> CreateAsync(CreateStructureDto request, CancellationToken cancellationToken)
    {
        if (!await _campusRepository.ExistsAsync(c => c.Id == request.CampusId, cancellationToken))
            return (null, $"El campus con ID '{request.CampusId}' no existe.");

        if (!await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId, cancellationToken))
            return (null, $"La categoría con ID '{request.CategoryId}' no existe.");

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        var structure = new Structure(request.Name, coordinates, request.CampusId, request.CategoryId);

        await _repository.AddAsync(structure, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        return (structure.ToDto(), null);
    }

    public async Task<(bool success, string? error)> UpdateAsync(Guid id, UpdateStructureDto request, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        if (structure == null) return (false, null); // Not found

        if (!await _campusRepository.ExistsAsync(c => c.Id == request.CampusId, cancellationToken))
            return (false, $"El campus con ID '{request.CampusId}' no existe.");

        if (!await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId, cancellationToken))
            return (false, $"La categoría con ID '{request.CategoryId}' no existe.");

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        structure.Update(request.Name, coordinates, request.CampusId, request.CategoryId);

        _repository.Update(structure);
        await _repository.SaveChangesAsync(cancellationToken);
        return (true, null);
    }

    public async Task<IEnumerable<StructureLocationDto>> GetAllLocationsAsync(Guid? campusId, Guid? categoryId, CancellationToken cancellationToken)
    {
        var structures = (await _repository.GetAllAsync(BuildFilterPredicate(campusId, categoryId), cancellationToken)).ToList();
        if (structures.Count == 0)
            return Array.Empty<StructureLocationDto>();

        var categoryIds = structures.Select(s => s.CategoryId).Distinct().ToHashSet();
        var categories = (await _categoryRepository.GetAllAsync(c => categoryIds.Contains(c.Id), cancellationToken))
            .ToDictionary(c => c.Id);

        return structures.Select(s => categories.TryGetValue(s.CategoryId, out var category)
            ? s.ToLocationDto(category.Name, category.Icon)
            : s.ToLocationDto(string.Empty, string.Empty));
    }

    private static Expression<Func<Structure, bool>>? BuildFilterPredicate(Guid? campusId, Guid? categoryId) =>
        (campusId, categoryId) switch
        {
            ({ } cId, { } catId) => s => s.CampusId == cId && s.CategoryId == catId,
            ({ } cId, null) => s => s.CampusId == cId,
            (null, { } catId) => s => s.CategoryId == catId,
            _ => null
        };

    public async Task<bool> UpdateLocationAsync(Guid id, UpdateLocationDto request, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        if (structure == null) return false;

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        structure.UpdateLocation(coordinates);

        _repository.Update(structure);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        if (structure == null) return false;

        _repository.Delete(structure);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
