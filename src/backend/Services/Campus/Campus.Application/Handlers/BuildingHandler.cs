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

    public BuildingHandler(IGenericRepository<Building> repository, IGenericRepository<Campus.Domain.Entities.Campus> campusRepository)
    {
        _repository = repository;
        _campusRepository = campusRepository;
    }

    public async Task<IEnumerable<BuildingDto>> GetAllAsync(Guid? campusId, CancellationToken cancellationToken)
    {
        var buildings = await _repository.GetAllAsync(campusId.HasValue ? b => b.CampusId == campusId.Value : null, cancellationToken);
        return buildings.Select(b => b.ToDto());
    }

    public async Task<IEnumerable<BuildingLocationDto>> GetAllLocationsAsync(Guid? campusId, CancellationToken cancellationToken)
    {
        var buildings = await _repository.GetAllAsync(campusId.HasValue ? b => b.CampusId == campusId.Value : null, cancellationToken);
        return buildings.Select(b => b.ToLocationDto());
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

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        var building = new Building(request.Name, request.FloorsCount, coordinates, request.CampusId, request.OpenTime, request.CloseTime, request.Services);

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

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        building.Update(request.Name, request.FloorsCount, coordinates, request.CampusId, request.OpenTime, request.CloseTime, request.Services);

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
