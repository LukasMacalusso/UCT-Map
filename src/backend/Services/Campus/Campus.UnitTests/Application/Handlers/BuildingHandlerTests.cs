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
using Campus.Domain.ValueObjects;
using ErrorOr;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.Application.Handlers;

public class BuildingHandlerTests
{
    private readonly IGenericRepository<Building> _repository;
    private readonly IGenericRepository<CampusEntity> _campusRepository;
    private readonly BuildingHandler _handler;

    public BuildingHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Building>>();
        _campusRepository = Substitute.For<IGenericRepository<CampusEntity>>();
        _handler = new BuildingHandler(_repository, _campusRepository);
    }

    [Fact]
    public async Task GetAllAsync_WithoutFilter_ShouldReturnAllBuildings()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(-38.7, -72.5), campusId),
            new("Edificio B", 4, new Coordinate(-38.8, -72.6), campusId)
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = await _handler.GetAllAsync(null, CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Edificio A", list[0].Name);
    }

    [Fact]
    public async Task GetAllAsync_WithCampusId_ShouldPassPredicate()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(-38.7, -72.5), campusId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = await _handler.GetAllAsync(campusId, CancellationToken.None);

        Assert.Single(result);
    }

    [Fact]
    public async Task GetAllLocationsAsync_ShouldReturnLocationsDto()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new("Edificio Central", 5, new Coordinate(-38.73, -72.59), campusId)
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = await _handler.GetAllLocationsAsync(null, CancellationToken.None);

        var location = Assert.Single(result);
        Assert.Equal("Edificio Central", location.Name);
        Assert.Equal(-38.73, location.Location.Latitude);
        Assert.Equal(-72.59, location.Location.Longitude);
        Assert.Equal(campusId, location.Metadata.CampusId);
        Assert.Equal(5, location.Metadata.FloorsCount);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var building = new Building("Edificio A", 3, new Coordinate(-38.7, -72.5), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        var result = await _handler.GetByIdAsync(building.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Edificio A", result.Value.Name);
        Assert.Equal(3, result.Value.FloorsCount);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_WhenCampusNotFound_ShouldReturnCampusNotFoundError()
    {
        var campusId = Guid.NewGuid();
        var request = new CreateBuildingDto(campusId, "Edificio C", 2, -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Campus.NotFound", result.FirstError.Code);
        await _repository.DidNotReceive().AddAsync(Arg.Any<Building>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task CreateAsync_WhenValid_ShouldPersistAndReturnDto()
    {
        var campusId = Guid.NewGuid();
        var request = new CreateBuildingDto(campusId, "Edificio C", 2, -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Edificio C", result.Value.Name);
        Assert.Equal(2, result.Value.FloorsCount);
        Assert.Equal(campusId, result.Value.CampusId);

        await _repository.Received(1).AddAsync(Arg.Is<Building>(b => b.Name == "Edificio C"), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenBuildingNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var request = new UpdateBuildingDto(Guid.NewGuid(), "Nuevo", 3, 0, 0);

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenCampusNotFound_ShouldReturnCampusNotFoundError()
    {
        var building = new Building("Antiguo", 1, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateBuildingDto(Guid.NewGuid(), "Nuevo", 3, 0, 0);

        var result = await _handler.UpdateAsync(building.Id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Campus.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenValid_ShouldUpdateAndReturnSuccess()
    {
        var campusId = Guid.NewGuid();
        var building = new Building("Antiguo", 1, new Coordinate(0, 0), campusId);
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateBuildingDto(campusId, "Nuevo Nombre", 4, 10, 20);

        var result = await _handler.UpdateAsync(building.Id, request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        Assert.Equal("Nuevo Nombre", building.Name);
        Assert.Equal(4, building.FloorsCount);
        _repository.Received(1).Update(building);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task DeleteAsync_WhenFound_ShouldDeleteAndReturnSuccess()
    {
        var building = new Building("Para Borrar", 1, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        var result = await _handler.DeleteAsync(building.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        _repository.Received(1).Delete(building);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
