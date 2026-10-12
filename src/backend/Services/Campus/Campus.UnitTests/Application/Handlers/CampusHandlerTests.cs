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
    private readonly IGenericRepository<CampusEntity> _repository;
    private readonly CampusHandler _handler;

    public CampusHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<CampusEntity>>();
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
}
