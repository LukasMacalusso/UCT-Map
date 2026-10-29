using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Campus.Domain.Entities;
using Campus.Application.DTOs;
using ErrorOr;

namespace Campus.Application.Handlers;

public class RoomHandler
{
    private readonly IGenericRepository<Room> _repository;
    private readonly IGenericRepository<Building> _buildingRepository;
    private readonly IGenericRepository<Category> _categoryRepository;

    public RoomHandler(IGenericRepository<Room> repository, IGenericRepository<Building> buildingRepository, IGenericRepository<Category> categoryRepository)
    {
        _repository = repository;
        _buildingRepository = buildingRepository;
        _categoryRepository = categoryRepository;
    }

    public async Task<IEnumerable<RoomDto>> GetAllAsync(Guid? buildingId, Guid? categoryId, CancellationToken cancellationToken)
    {
        var rooms = await _repository.GetAllAsync(r => (!buildingId.HasValue || r.BuildingId == buildingId.Value) && (!categoryId.HasValue || r.CategoryId == categoryId.Value), cancellationToken);
        return rooms.Select(r => new RoomDto(r.Id, r.BuildingId, r.CategoryId, r.Name, r.Floor));
    }

    public async Task<IEnumerable<RoomDto>> SearchRoomsAsync(string term, CancellationToken cancellationToken)
    {
        var rooms = await _repository.GetAllAsync(r => r.Name.Contains(term), cancellationToken);
        return rooms.Select(r => new RoomDto(r.Id, r.BuildingId, r.CategoryId, r.Name, r.Floor));
    }

    public async Task<IEnumerable<RoomDto>> GetRoomsByBuildingAsync(Guid buildingId, CancellationToken cancellationToken)
    {
        var rooms = await _repository.GetAllAsync(r => r.BuildingId == buildingId, cancellationToken);
        return rooms.Select(r => new RoomDto(r.Id, r.BuildingId, r.CategoryId, r.Name, r.Floor));
    }

    public async Task<ErrorOr<RoomDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var room = await _repository.GetByIdAsync(id, cancellationToken);
        if (room == null) return Error.NotFound("Room.NotFound", $"Room with ID '{id}' was not found.");
        return new RoomDto(room.Id, room.BuildingId, room.CategoryId, room.Name, room.Floor);
    }

    public async Task<ErrorOr<RoomDto>> CreateAsync(CreateRoomDto request, CancellationToken cancellationToken)
    {
        if (!await _buildingRepository.ExistsAsync(b => b.Id == request.BuildingId, cancellationToken))
            return Error.NotFound("Building.NotFound", $"Building with ID '{request.BuildingId}' does not exist.");

        if (!await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId, cancellationToken))
            return Error.NotFound("Category.NotFound", $"Category with ID '{request.CategoryId}' does not exist.");

        var room = new Room(request.Name, request.Floor, request.BuildingId, request.CategoryId);

        await _repository.AddAsync(room, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        return new RoomDto(room.Id, room.BuildingId, room.CategoryId, room.Name, room.Floor);
    }

    public async Task<ErrorOr<Success>> UpdateAsync(Guid id, UpdateRoomDto request, CancellationToken cancellationToken)
    {
        var room = await _repository.GetByIdAsync(id, cancellationToken);
        if (room == null) return Error.NotFound("Room.NotFound", $"Room with ID '{id}' was not found.");

        if (!await _buildingRepository.ExistsAsync(b => b.Id == request.BuildingId, cancellationToken))
            return Error.NotFound("Building.NotFound", $"Building with ID '{request.BuildingId}' does not exist.");

        if (!await _categoryRepository.ExistsAsync(c => c.Id == request.CategoryId, cancellationToken))
            return Error.NotFound("Category.NotFound", $"Category with ID '{request.CategoryId}' does not exist.");

        room.Update(request.Name, request.Floor, request.BuildingId, request.CategoryId);

        _repository.Update(room);
        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }

    public async Task<ErrorOr<Success>> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var room = await _repository.GetByIdAsync(id, cancellationToken);
        if (room == null) return Error.NotFound("Room.NotFound", $"Room with ID '{id}' was not found.");

        _repository.Delete(room);
        await _repository.SaveChangesAsync(cancellationToken);
        return Result.Success;
    }
}
