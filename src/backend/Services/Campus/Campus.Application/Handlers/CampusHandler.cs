using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.ValueObjects;
using Campus.Application.DTOs;
using Campus.Application.Mappers;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.Application.Handlers;

public class CampusHandler
{
    private readonly ICampusRepository _repository;

    public CampusHandler(ICampusRepository repository)
    {
        _repository = repository;
    }

    public async Task<IEnumerable<CampusDto>> GetAllAsync(CancellationToken cancellationToken)
    {
        var campuses = await _repository.GetAllAsync(null, cancellationToken);
        return campuses.Select(c => c.ToDto());
    }

    public async Task<CampusDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdAsync(id, cancellationToken);
        return campus?.ToDto();
    }

    public async Task<CampusMapDto?> GetMapByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdWithMapDataAsync(id, cancellationToken);
        return campus?.ToMapDto();
    }

    public async Task<CampusDto> CreateAsync(CreateCampusDto request, CancellationToken cancellationToken)
    {
        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        var campus = new CampusEntity(request.Name, request.Address, coordinates, request.Zoom, request.Pitch, request.Bearing);
        await _repository.AddAsync(campus, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);
        return campus.ToDto();
    }

    public async Task<bool> UpdateAsync(Guid id, UpdateCampusDto request, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdAsync(id, cancellationToken);
        if (campus == null) return false;

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        campus.Update(request.Name, request.Address, coordinates, request.Zoom, request.Pitch, request.Bearing);
        _repository.Update(campus);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UpdateLocationAsync(Guid id, UpdateLocationDto request, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdAsync(id, cancellationToken);
        if (campus == null) return false;

        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        campus.UpdateLocation(coordinates);

        _repository.Update(campus);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdAsync(id, cancellationToken);
        if (campus == null) return false;

        _repository.Delete(campus);
        await _repository.SaveChangesAsync(cancellationToken);
        return true;
    }
}
