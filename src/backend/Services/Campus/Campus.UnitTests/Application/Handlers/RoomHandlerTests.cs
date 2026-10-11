using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using Campus.Domain.Entities;
using Campus.Domain.Interfaces;
using ErrorOr;
using NSubstitute;
using Xunit;

namespace Campus.UnitTests.Application.Handlers;

public class RoomHandlerTests
{
    private readonly IGenericRepository<Room> _repository;
    private readonly IGenericRepository<Building> _buildingRepository;
    private readonly IGenericRepository<Category> _categoryRepository;
    private readonly RoomHandler _handler;

    public RoomHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Room>>();
        _buildingRepository = Substitute.For<IGenericRepository<Building>>();
        _categoryRepository = Substitute.For<IGenericRepository<Category>>();
        _handler = new RoomHandler(_repository, _buildingRepository, _categoryRepository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldFilterByPredicate()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var rooms = new List<Room>
        {
            new("Sala 1", 1, "S-1", buildingId, categoryId),
            new("Sala 2", 2, "S-2", buildingId, categoryId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(rooms);

        var result = await _handler.GetAllAsync(buildingId, categoryId, CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Sala 1", list[0].Name);
    }

    [Fact]
    public async Task SearchRoomsAsync_ShouldCallGetAllWithPredicate()
    {
        var rooms = new List<Room>
        {
            new("Laboratorio de Física", 1, "LAB-1", Guid.NewGuid(), Guid.NewGuid())
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(rooms);

        var result = await _handler.SearchRoomsAsync("Física", CancellationToken.None);

        var room = Assert.Single(result);
        Assert.Equal("Laboratorio de Física", room.Name);
    }

    [Fact]
    public async Task GetRoomsByBuildingAsync_ShouldCallGetAllWithBuildingPredicate()
    {
        var buildingId = Guid.NewGuid();
        var rooms = new List<Room>
        {
            new("Sala 101", 1, "101", buildingId, Guid.NewGuid())
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(rooms);

        var result = await _handler.GetRoomsByBuildingAsync(buildingId, CancellationToken.None);

        var room = Assert.Single(result);
        Assert.Equal("Sala 101", room.Name);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnRoomDto()
    {
        var room = new Room("Sala 102", 1, "102", Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>())
            .Returns(room);

        var result = await _handler.GetByIdAsync(room.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Sala 102", result.Value.Name);
        Assert.Equal(1, result.Value.Floor);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Room?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Room.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_WhenBuildingNotFound_ShouldReturnBuildingNotFoundError()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateRoomDto(buildingId, categoryId, "Sala 103", 1, "103");

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_WhenCategoryNotFound_ShouldReturnCategoryNotFoundError()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateRoomDto(buildingId, categoryId, "Sala 103", 1, "103");

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Category.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_WhenValid_ShouldPersistAndReturnDto()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateRoomDto(buildingId, categoryId, "Sala 103", 1, "103");

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Sala 103", result.Value.Name);
        Assert.Equal(buildingId, result.Value.BuildingId);
        Assert.Equal(categoryId, result.Value.CategoryId);

        await _repository.Received(1).AddAsync(Arg.Is<Room>(r => r.Name == "Sala 103"), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenRoomNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Room?)null);

        var request = new UpdateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "Nueva", 2, "200");

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Room.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenBuildingNotFound_ShouldReturnBuildingNotFoundError()
    {
        var room = new Room("Antigua", 1, "100", Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>())
            .Returns(room);

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "Nueva", 2, "200");

        var result = await _handler.UpdateAsync(room.Id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenCategoryNotFound_ShouldReturnCategoryNotFoundError()
    {
        var room = new Room("Antigua", 1, "100", Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>())
            .Returns(room);

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "Nueva", 2, "200");

        var result = await _handler.UpdateAsync(room.Id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Category.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenValid_ShouldUpdateAndReturnSuccess()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var room = new Room("Antigua", 1, "100", buildingId, categoryId);
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>())
            .Returns(room);

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateRoomDto(buildingId, categoryId, "Actualizada", 3, "305");

        var result = await _handler.UpdateAsync(room.Id, request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        Assert.Equal("Actualizada", room.Name);
        Assert.Equal(3, room.Floor);
        Assert.Equal("305", room.Number);
        _repository.Received(1).Update(room);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Room?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Room.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task DeleteAsync_WhenFound_ShouldDeleteAndReturnSuccess()
    {
        var room = new Room("Para Borrar", 1, null, Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>())
            .Returns(room);

        var result = await _handler.DeleteAsync(room.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        _repository.Received(1).Delete(room);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
