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
using Campus.Domain.ValueObjects;
using Microsoft.AspNetCore.Mvc;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.API.Controllers;

public class StructureControllerTests
{
    private readonly IGenericRepository<Structure> _repository;
    private readonly IGenericRepository<CampusEntity> _campusRepository;
    private readonly IGenericRepository<Category> _categoryRepository;
    private readonly StructureHandler _handler;
    private readonly StructureController _controller;

    public StructureControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<Structure>>();
        _campusRepository = Substitute.For<IGenericRepository<CampusEntity>>();
        _categoryRepository = Substitute.For<IGenericRepository<Category>>();
        _handler = new StructureHandler(_repository, _campusRepository, _categoryRepository);
        _controller = new StructureController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithStructures()
    {
        var structures = new List<Structure>
        {
            new("Pérgola", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid())
        };
        _repository.GetAllAsync(Arg.Any<Expression<Func<Structure, bool>>>(), Arg.Any<CancellationToken>()).Returns(structures);

        var result = await _controller.GetAll(null, null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<StructureDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetAll_WithEmptyCampusId_ShouldReturnBadRequest()
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
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var structure = new Structure("Cancha", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>()).Returns(structure);

        var result = await _controller.GetById(structure.Id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dto = Assert.IsType<StructureDto>(okResult.Value);
        Assert.Equal("Cancha", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Structure?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "", 0, 0);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenCampusOrCategoryNotFound_ShouldReturnBadRequest()
    {
        var request = new CreateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Pérgola", 0, 0);
        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(false);

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var campusId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateStructureDto(campusId, categoryId, "Pérgola", 0, 0);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<StructureDto>(created.Value);
        Assert.Equal("Pérgola", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "", 0, 0);

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenCategoryNotFound_ShouldReturnBadRequest()
    {
        var structure = new Structure("Viejo", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>()).Returns(structure);
        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(false);

        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Nuevo", 0, 0);

        var result = await _controller.Update(structure.Id, request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Structure?)null);

        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Nuevo", 0, 0);

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NotFoundResult>(result);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var campusId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var structure = new Structure("Viejo", new Coordinate(0, 0), campusId, categoryId);

        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>()).Returns(structure);
        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var request = new UpdateStructureDto(campusId, categoryId, "Nuevo", 0, 0);

        var result = await _controller.Update(structure.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task GetLocations_ShouldReturnOkWithStructureLocations()
    {
        var categoryId = Guid.NewGuid();
        var structures = new List<Structure>
        {
            new("Pérgola", new Coordinate(-38.73, -72.60), Guid.NewGuid(), categoryId)
        };
        var categories = new List<Category>
        {
            new("Recreación", "icon", "desc", Guid.NewGuid())
        };
        // Reflection or setter trick for Category Id if protected, or category mock
        typeof(Category).GetProperty("Id")?.SetValue(categories[0], categoryId);

        _repository.GetAllAsync(Arg.Any<Expression<Func<Structure, bool>>>(), Arg.Any<CancellationToken>()).Returns(structures);
        _categoryRepository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(categories);

        var result = await _controller.GetLocations(null, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<StructureLocationDto>>(okResult.Value);
        Assert.Single(dtos);
        Assert.Equal("Recreación", dtos.First().Metadata.CategoryName);
    }

    [Fact]
    public async Task GetLocations_WithEmptyCampusId_ShouldReturnBadRequest()
    {
        var result = await _controller.GetLocations(Guid.Empty, CancellationToken.None);

        var badRequestResult = Assert.IsType<BadRequestObjectResult>(result.Result);
        Assert.NotNull(badRequestResult.Value);
    }

    [Fact]
    public async Task UpdateLocation_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Structure?)null);

        var request = new UpdateLocationDto(10.5, 20.5);
        var result = await _controller.UpdateLocation(id, request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task UpdateLocation_WhenValid_ShouldReturnNoContent()
    {
        var structure = new Structure("Structure", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>()).Returns(structure);

        var request = new UpdateLocationDto(-38.73, -72.60);
        var result = await _controller.UpdateLocation(structure.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(-38.73, structure.Coordinates.Latitude);
        Assert.Equal(-72.60, structure.Coordinates.Longitude);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Structure?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Delete_WhenValid_ShouldReturnNoContent()
    {
        var structure = new Structure("Borrar", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>()).Returns(structure);

        var result = await _controller.Delete(structure.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
