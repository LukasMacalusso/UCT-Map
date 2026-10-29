using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.ValueObjects;
using Campus.Application.DTOs;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.Application.Handlers;

public class CampusHandler
{
    private readonly IGenericRepository<CampusEntity> _repository;

    public CampusHandler(IGenericRepository<CampusEntity> repository)
    {
        _repository = repository;
    }

    public async Task<IEnumerable<CampusDto>> GetAllAsync(CancellationToken cancellationToken)
    {
        var campuses = await _repository.GetAllAsync(null, cancellationToken);
        return campuses.Select(c => new CampusDto(c.Id, c.Name, c.Address, c.Coordinates.Latitude, c.Coordinates.Longitude, c.Zoom, c.Pitch, c.Bearing));
    }

    public async Task<CampusDto?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var campus = await _repository.GetByIdAsync(id, cancellationToken);
        if (campus == null) return null;
        return new CampusDto(campus.Id, campus.Name, campus.Address, campus.Coordinates.Latitude, campus.Coordinates.Longitude, campus.Zoom, campus.Pitch, campus.Bearing);
    }

    public async Task<CampusDto> CreateAsync(CreateCampusDto request, CancellationToken cancellationToken)
    {
        var coordinates = new Coordinate(request.Latitude, request.Longitude);
        var campus = new CampusEntity(request.Name, request.Address, coordinates, request.Zoom, request.Pitch, request.Bearing);
        await _repository.AddAsync(campus, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);
        return new CampusDto(campus.Id, campus.Name, campus.Address, campus.Coordinates.Latitude, campus.Coordinates.Longitude, campus.Zoom, campus.Pitch, campus.Bearing);
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
