using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Threading;
using System.Threading.Tasks;
using Campus.API.Controllers;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using Campus.Domain.Entities;
using Campus.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using NSubstitute;
using Xunit;

namespace Campus.UnitTests.API.Controllers;

public class RoomControllerTests
{
    private readonly IGenericRepository<Room> _repository;
    private readonly IGenericRepository<Building> _buildingRepository;
    private readonly IGenericRepository<Category> _categoryRepository;
    private readonly RoomHandler _handler;
    private readonly RoomController _controller;

    public RoomControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<Room>>();
        _buildingRepository = Substitute.For<IGenericRepository<Building>>();
        _categoryRepository = Substitute.For<IGenericRepository<Category>>();
        _handler = new RoomHandler(_repository, _buildingRepository, _categoryRepository);
        _controller = new RoomController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithRooms()
    {
        var rooms = new List<Room>
        {
            new("101", 1, Guid.NewGuid(), Guid.NewGuid())
        };
        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>()).Returns(rooms);

        var result = await _controller.GetAll(null, null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<RoomDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetAll_WithEmptyBuildingId_ShouldReturnBadRequest()
    {
        var result = await _controller.GetAll(Guid.Empty, null, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.NotNull(badRequestResult.Value);
    }

    [Fact]
    public async Task GetAll_WithEmptyCategoryId_ShouldReturnBadRequest()
    {
        var result = await _controller.GetAll(null, Guid.Empty, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.NotNull(badRequestResult.Value);
    }

    [Fact]
    public async Task Search_ShouldReturnOkWithMatchingRooms()
    {
        var rooms = new List<Room>
        {
            new("LQ-1", 1, Guid.NewGuid(), Guid.NewGuid())
        };
        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>()).Returns(rooms);

        var result = await _controller.Search("LQ", CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<RoomDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetByBuilding_ShouldReturnOkWithBuildingRooms()
    {
        var buildingId = Guid.NewGuid();
        var rooms = new List<Room>
        {
            new("201", 2, buildingId, Guid.NewGuid())
        };
        _repository.GetAllAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>()).Returns(rooms);

        var result = await _controller.GetByBuilding(buildingId, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<RoomDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var room = new Room("1", 1, Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>()).Returns(room);

        var result = await _controller.GetById(room.Id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result);
        var dto = Assert.IsType<RoomDto>(okResult.Value);
        Assert.Equal("1", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Room?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "", 1);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Create_WhenBuildingOrCategoryNotFound_ShouldReturnProblem404()
    {
        var request = new CreateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "1", 1);
        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>()).Returns(false);

        var result = await _controller.Create(request, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateRoomDto(buildingId, categoryId, "1", 1);

        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result);
        var dto = Assert.IsType<RoomDto>(created.Value);
        Assert.Equal("1", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "", 1);

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Room?)null);

        var request = new UpdateRoomDto(Guid.NewGuid(), Guid.NewGuid(), "1", 1);

        var result = await _controller.Update(id, request, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var buildingId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var room = new Room("1", 1, buildingId, categoryId);

        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>()).Returns(room);
        _buildingRepository.ExistsAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var request = new UpdateRoomDto(buildingId, categoryId, "2", 2);

        var result = await _controller.Update(room.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnProblem404()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Room?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task Delete_WhenValid_ShouldReturnNoContent()
    {
        var room = new Room("Borrar", 1, Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(room.Id, Arg.Any<CancellationToken>()).Returns(room);

        var result = await _controller.Delete(room.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
