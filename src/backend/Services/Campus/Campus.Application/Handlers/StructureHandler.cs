using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Campus.Application.DTOs;

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
        var structures = await _repository.GetAllAsync(s =>
            (!campusId.HasValue || s.CampusId == campusId.Value) &&
            (!categoryId.HasValue || s.CategoryId == categoryId.Value),
        cancellationToken);

        return structures.Select(s => new StructureDto(s.Id, s.CampusId, s.CategoryId, s.Name, s.Coordinates.Latitude, s.Coordinates.Longitude));
    }

    public async Task<StructureDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        if (structure == null) return null;
        return new StructureDto(structure.Id, structure.CampusId, structure.CategoryId, structure.Name, structure.Coordinates.Latitude, structure.Coordinates.Longitude);
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

        return (new StructureDto(structure.Id, structure.CampusId, structure.CategoryId, structure.Name, structure.Coordinates.Latitude, structure.Coordinates.Longitude), null);
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

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var structure = await _repository.GetByIdAsync(id, cancellationToken);
        if (structure == null) return false;

        _repository.Delete(structure);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
