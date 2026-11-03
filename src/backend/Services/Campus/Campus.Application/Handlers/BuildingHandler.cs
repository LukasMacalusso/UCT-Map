using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Campus.Application.DTOs;
using Campus.Application.Mappers;
using ErrorOr;

namespace Campus.Application.Handlers;

public class BuildingHandler
{
    private readonly IGenericRepository<Building> _repository;
    private readonly IGenericRepository<Campus.Domain.Entities.Campus> _campusRepository;
    private readonly IGenericRepository<Category>? _categoryRepository;

    public BuildingHandler(
        IGenericRepository<Building> repository,
        IGenericRepository<Campus.Domain.Entities.Campus> campusRepository,
        IGenericRepository<Category>? categoryRepository = null)
    {
        _repository = repository;
        _campusRepository = campusRepository;
        _categoryRepository = categoryRepository;
    }

    public async Task<IEnumerable<BuildingDto>> GetAllAsync(Guid? campusId, Guid? categoryId, CancellationToken cancellationToken)
    {
        var predicate = BuildFilterPredicate(campusId, categoryId);
        var buildings = await _repository.GetAllAsync(predicate, cancellationToken);
        return buildings.Select(b => b.ToDto());
    }

    public Task<IEnumerable<BuildingDto>> GetAllAsync(Guid? campusId, CancellationToken cancellationToken) =>
        GetAllAsync(campusId, null, cancellationToken);

    public async Task<IEnumerable<BuildingLocationDto>> GetAllLocationsAsync(Guid? campusId, Guid? categoryId, CancellationToken cancellationToken)
    {
        var predicate = BuildFilterPredicate(campusId, categoryId);
        var buildings = await _repository.GetAllAsync(predicate, cancellationToken);
        return buildings.Select(b => b.ToLocationDto());
    }

    public Task<IEnumerable<BuildingLocationDto>> GetAllLocationsAsync(Guid? campusId, CancellationToken cancellationToken) =>
        GetAllLocationsAsync(campusId, null, cancellationToken);

    private static System.Linq.Expressions.Expression<Func<Building, bool>>? BuildFilterPredicate(Guid? campusId, Guid? categoryId)
    {
        if (!campusId.HasValue && !categoryId.HasValue) return null;
        return b => (!campusId.HasValue || b.CampusId == campusId.Value) &&
                    (!categoryId.HasValue || b.CategoryId == categoryId.Value);
    }

    public async Task<ErrorOr<BuildingDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var building = await _repository.GetByIdAsync(id, cancellationToken);
        if (building == null)
            return Error.NotFound("Building.NotFound", $"Building with ID '{id}' was not found.");

        return building.ToDto();
    }

    public async Task<ErrorOr<BuildingDto>> CreateAsync(CreateBuildingDto request, CancellationToken cancellationToken)
    {
        if (!await _campusRepository.ExistsAsync(c => c.Id == request.CampusId, cancellationToken))
            return Error.NotFound("Campus.NotFound", $"Campus with ID '{request.CampusId}' does not exist.");

        if (request.CategoryId.HasValue && _categoryRepository != null)
        {
            if (request.CategoryId.Value == Guid.Empty || !await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId.Value, cancellationToken))
                return Error.NotFound("Category.NotFound", $"Category with ID '{request.CategoryId.Value}' does not exist.");
        }

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        var building = new Building(request.Name, request.FloorsCount, coordinates, request.CampusId, request.OpenTime, request.CloseTime, request.Services, request.CategoryId);

        await _repository.AddAsync(building, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        return building.ToDto();
    }

    public async Task<ErrorOr<Success>> UpdateAsync(Guid id, UpdateBuildingDto request, CancellationToken cancellationToken)
    {
        var building = await _repository.GetByIdAsync(id, cancellationToken);
        if (building == null)
            return Error.NotFound("Building.NotFound", $"Building with ID '{id}' was not found.");

        if (!await _campusRepository.ExistsAsync(c => c.Id == request.CampusId, cancellationToken))
            return Error.NotFound("Campus.NotFound", $"Campus with ID '{request.CampusId}' does not exist.");

        if (request.CategoryId.HasValue && _categoryRepository != null)
        {
            if (request.CategoryId.Value == Guid.Empty || !await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId.Value, cancellationToken))
                return Error.NotFound("Category.NotFound", $"Category with ID '{request.CategoryId.Value}' does not exist.");
        }

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        building.Update(request.Name, request.FloorsCount, coordinates, request.CampusId, request.OpenTime, request.CloseTime, request.Services, request.CategoryId);

        _repository.Update(building);
        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }

    public async Task<ErrorOr<Success>> UpdateLocationAsync(Guid id, UpdateLocationDto request, CancellationToken cancellationToken)
    {
        var building = await _repository.GetByIdAsync(id, cancellationToken);
        if (building == null)
            return Error.NotFound("Building.NotFound", $"Building with ID '{id}' was not found.");

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        building.UpdateLocation(coordinates);

        _repository.Update(building);
        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }

    public async Task<ErrorOr<Success>> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var building = await _repository.GetByIdAsync(id, cancellationToken);
        if (building == null)
            return Error.NotFound("Building.NotFound", $"Building with ID '{id}' was not found.");

        _repository.Delete(building);
        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }
}
