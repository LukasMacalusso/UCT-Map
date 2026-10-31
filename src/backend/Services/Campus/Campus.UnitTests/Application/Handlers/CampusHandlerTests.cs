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
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.Application.Handlers;

public class CampusHandlerTests
{
    private readonly ICampusRepository _repository;
    private readonly CampusHandler _handler;

    public CampusHandlerTests()
    {
        _repository = Substitute.For<ICampusRepository>();
        _handler = new CampusHandler(_repository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnMappedDtos()
    {
        var campuses = new List<CampusEntity>
        {
            new("Campus Norte", "Dirección 1", new Coordinate(-38.71, -72.58)),
            new("Campus Sur", "Dirección 2", new Coordinate(-38.72, -72.59))
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(campuses);

        var result = await _handler.GetAllAsync(CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Campus Norte", list[0].Name);
        Assert.Equal("Campus Sur", list[1].Name);
        Assert.Equal(-38.71, list[0].Latitude);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Campus San Juan Pablo II", "Rudecindo Ortega 02950", new Coordinate(-38.73, -72.59));

        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(entity);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("Campus San Juan Pablo II", result.Name);
        Assert.Equal("Rudecindo Ortega 02950", result.Address);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((CampusEntity?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task CreateAsync_ShouldPersistAndReturnDto()
    {
        var request = new CreateCampusDto("Campus San Francisco", "Manuel Montt 056", -38.74, -72.60);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.NotNull(result);
        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Campus San Francisco", result.Name);
        Assert.Equal("Manuel Montt 056", result.Address);
        Assert.Equal(-38.74, result.Latitude);
        Assert.Equal(-72.60, result.Longitude);

        await _repository.Received(1).AddAsync(Arg.Is<CampusEntity>(c => c.Name == request.Name), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_ShouldUpdateAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Antiguo", "Antigua Dir", new Coordinate(0, 0));
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(entity);

        var request = new UpdateCampusDto("Nuevo", "Nueva Dir", 10, 20);

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result);
        Assert.Equal("Nuevo", entity.Name);
        Assert.Equal("Nueva Dir", entity.Address);
        _repository.Received(1).Update(entity);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((CampusEntity?)null);

        var request = new UpdateCampusDto("Nuevo", "Nueva Dir", 10, 20);

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.False(result);
        _repository.DidNotReceive().Update(Arg.Any<CampusEntity>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_ShouldDeleteAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Campus Para Eliminar", "Dir", new Coordinate(0, 0));
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(entity);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result);
        _repository.Received(1).Delete(entity);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((CampusEntity?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(result);
        _repository.DidNotReceive().Delete(Arg.Any<CampusEntity>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetMapByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdWithMapDataAsync(id, Arg.Any<CancellationToken>())
            .Returns((CampusEntity?)null);

        var result = await _handler.GetMapByIdAsync(id, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetMapByIdAsync_WhenExists_ShouldReturnUnifiedCampusMapDto()
    {
        var campus = new CampusEntity(
            "Campus San Francisco",
            "Manuel Montt 056",
            new Coordinate(-38.7335, -72.6020),
            zoom: 16.0m,
            pitch: 50.0m,
            bearing: -20.0m
        );
        var group = new CategoryGroup("Espacios Comunes");
        var category = new Category("Sala de Estudio", "users", "Espacio grupal", group);
        var building = new Building(
            "Edificio 16",
            3,
            new Coordinate(-38.7336, -72.6021),
            campus,
            openTime: new TimeOnly(8, 0),
            closeTime: new TimeOnly(21, 0),
            services: "Wifi, Baños, Calefacción"
        );
        var structureWithCategory = new Structure(
            "Punto de Estudio",
            new Coordinate(-38.7338, -72.6025),
            campus,
            category
        );
        var structureWithoutCategory = new Structure(
            "Banca Exterior",
            new Coordinate(-38.7340, -72.6028),
            campus.Id,
            Guid.NewGuid()
        );

        campus.Buildings.Add(building);
        campus.Structures.Add(structureWithCategory);
        campus.Structures.Add(structureWithoutCategory);

        _repository.GetByIdWithMapDataAsync(campus.Id, Arg.Any<CancellationToken>())
            .Returns(campus);

        var result = await _handler.GetMapByIdAsync(campus.Id, CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal(campus.Id, result.Id);
        Assert.Equal("Campus San Francisco", result.Name);
        Assert.Equal(-38.7335, result.Camera.Center.Latitude);
        Assert.Equal(-72.6020, result.Camera.Center.Longitude);
        Assert.Equal(16.0m, result.Camera.Zoom);
        Assert.Equal(50.0m, result.Camera.Pitch);
        Assert.Equal(-20.0m, result.Camera.Bearing);

        var mappedBuilding = Assert.Single(result.Buildings);
        Assert.Equal("Edificio 16", mappedBuilding.Name);
        Assert.Equal("08:00 - 21:00", mappedBuilding.Metadata.Schedule);
        Assert.Equal(new[] { "Wifi", "Baños", "Calefacción" }, mappedBuilding.Metadata.Services);

        Assert.Equal(2, result.Structures.Count);
        Assert.Equal("Sala de Estudio", result.Structures[0].Metadata.CategoryName);
        Assert.Equal("users", result.Structures[0].Metadata.CategoryIcon);
        Assert.Equal(string.Empty, result.Structures[1].Metadata.CategoryName);
        Assert.Equal(string.Empty, result.Structures[1].Metadata.CategoryIcon);
    }
}
