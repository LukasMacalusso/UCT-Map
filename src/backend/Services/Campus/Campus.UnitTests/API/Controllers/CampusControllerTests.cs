using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.API.Controllers;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using Campus.Domain.Entities;
using Campus.Domain.Interfaces;
using Campus.Domain.ValueObjects;
using Microsoft.AspNetCore.Mvc;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.API.Controllers;

public class CampusControllerTests
{
    private readonly IGenericRepository<CampusEntity> _repository;
    private readonly CampusHandler _handler;
    private readonly CampusController _controller;

    public CampusControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<CampusEntity>>();
        _handler = new CampusHandler(_repository);
        _controller = new CampusController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithCampuses()
    {
        var campuses = new List<CampusEntity>
        {
            new("Campus Central", "Dir 1", new Coordinate(0, 0))
        };
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(campuses);

        var result = await _controller.GetAll(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<CampusDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Campus Norte", "Dir 2", new Coordinate(0, 0));
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns(entity);

        var result = await _controller.GetById(id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dto = Assert.IsType<CampusDto>(okResult.Value);
        Assert.Equal("Campus Norte", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CampusEntity?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateCampusDto("", "Dir", 0, 0);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
        await _repository.DidNotReceive().AddAsync(Arg.Any<CampusEntity>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var request = new CreateCampusDto("Campus San Francisco", "Manuel Montt", 10, 20);

        var result = await _controller.Create(request, CancellationToken.None);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<CampusDto>(createdResult.Value);
        Assert.Equal("Campus San Francisco", dto.Name);
        Assert.Equal(nameof(CampusController.GetById), createdResult.ActionName);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var id = Guid.NewGuid();
        var request = new UpdateCampusDto("   ", "Dir", 0, 0);

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CampusEntity?)null);

        var request = new UpdateCampusDto("Nuevo", "Dir", 0, 0);

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Viejo", "Dir", new Coordinate(0, 0));
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns(entity);

        var request = new UpdateCampusDto("Nuevo", "Nueva Dir", 0, 0);

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CampusEntity?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Delete_WhenFound_ShouldReturnNoContent()
    {
        var id = Guid.NewGuid();
        var entity = new CampusEntity("Viejo", "Dir", new Coordinate(0, 0));
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns(entity);

        var result = await _controller.Delete(id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
