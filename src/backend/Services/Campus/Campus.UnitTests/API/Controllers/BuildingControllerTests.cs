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
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.API.Controllers;

public class BuildingControllerTests
{
    private readonly IGenericRepository<Building> _repository;
    private readonly IGenericRepository<CampusEntity> _campusRepository;
    private readonly BuildingHandler _handler;
    private readonly BuildingController _controller;

    public BuildingControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<Building>>();
        _campusRepository = Substitute.For<IGenericRepository<CampusEntity>>();
        _handler = new BuildingHandler(_repository, _campusRepository);
        _controller = new BuildingController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithBuildings()
    {
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(0, 0), Guid.NewGuid())
        };
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(buildings);

        var result = await _controller.GetAll(null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<BuildingDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetAll_WithEmptyCampusId_ShouldReturnBadRequest()
    {
        var result = await _controller.GetAll(Guid.Empty, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.NotNull(badRequestResult.Value);
    }

    [Fact]
    public async Task GetLocations_ShouldReturnOkWithLocations()
    {
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(0, 0), Guid.NewGuid())
        };
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(buildings);

        var result = await _controller.GetLocations(null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<BuildingLocationDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetLocations_WithEmptyCampusId_ShouldReturnBadRequest()
    {
        var result = await _controller.GetLocations(Guid.Empty, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.NotNull(badRequestResult.Value);
    }

    [Fact]
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var building = new Building("Edificio A", 3, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);

        var result = await _controller.GetById(building.Id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<BuildingDto>(okResult.Value);
        Assert.Equal("Edificio A", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Building?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), "", 3, 0, 0);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenCampusNotFound_ShouldReturnProblem404()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), "Edificio A", 3, 0, 0);
        _campusRepository.ExistsAsync(Arg.Any<System.Linq.Expressions.Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(false);

        var result = await _controller.Create(request, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var campusId = Guid.NewGuid();
        var request = new CreateBuildingDto(campusId, "Edificio B", 3, 0, 0);
        _campusRepository.ExistsAsync(Arg.Any<System.Linq.Expressions.Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        var dto = Assert.IsType<BuildingDto>(created.Value);
        Assert.Equal("Edificio B", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateBuildingDto(Guid.NewGuid(), "", 3, 0, 0);

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Building?)null);

        var request = new UpdateBuildingDto(Guid.NewGuid(), "Edificio A", 3, 0, 0);

        var result = await _controller.Update(id, request, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var campusId = Guid.NewGuid();
        var building = new Building("Viejo", 2, new Coordinate(0, 0), campusId);
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);
        _campusRepository.ExistsAsync(Arg.Any<System.Linq.Expressions.Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var request = new UpdateBuildingDto(campusId, "Nuevo", 3, 0, 0);

        var result = await _controller.Update(building.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task UpdateLocation_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Building?)null);

        var request = new UpdateLocationDto(10.5, 20.5);
        var result = await _controller.UpdateLocation(id, request, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task UpdateLocation_WhenValid_ShouldReturnNoContent()
    {
        var building = new Building("Edificio", 2, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);

        var request = new UpdateLocationDto(-38.73, -72.60);
        var result = await _controller.UpdateLocation(building.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(-38.73, building.Coordinates.Latitude);
        Assert.Equal(-72.60, building.Coordinates.Longitude);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Building?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenValid_ShouldReturnNoContent()
    {
        var building = new Building("Borrar", 1, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);

        var result = await _controller.Delete(building.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Create_WhenCampusIdIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.Empty, "Edificio Valido", 3, -38.7, -72.6);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenNameExceeds100Characters_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), new string('A', 101), 3, -38.7, -72.6);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenFloorsCountIsLessThanOne_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), "Edificio A", 0, -38.7, -72.6);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenLatitudeIsOutOfRange_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), "Edificio A", 3, 95.0, -72.6);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenLongitudeIsOutOfRange_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(Guid.NewGuid(), "Edificio A", 3, -38.7, 185.0);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenOpenTimeIsLaterThanCloseTime_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(
            Guid.NewGuid(),
            "Edificio A",
            3,
            -38.7,
            -72.6,
            OpenTime: new TimeOnly(20, 0),
            CloseTime: new TimeOnly(8, 0)
        );

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenServicesExceeds150Characters_ShouldReturnBadRequest()
    {
        var request = new CreateBuildingDto(
            Guid.NewGuid(),
            "Edificio A",
            3,
            -38.7,
            -72.6,
            Services: new string('S', 151)
        );

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task UpdateLocation_WhenCoordinatesOutOfRange_ShouldReturnBadRequest()
    {
        var request = new UpdateLocationDto(100.0, -72.6);

        var result = await _controller.UpdateLocation(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }
}
