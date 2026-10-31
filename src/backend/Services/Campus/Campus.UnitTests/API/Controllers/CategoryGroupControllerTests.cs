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
using Microsoft.AspNetCore.Mvc;
using NSubstitute;
using Xunit;

namespace Campus.UnitTests.API.Controllers;

public class CategoryGroupControllerTests
{
    private readonly IGenericRepository<CategoryGroup> _repository;
    private readonly CategoryGroupHandler _handler;
    private readonly CategoryGroupController _controller;

    public CategoryGroupControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<CategoryGroup>>();
        _handler = new CategoryGroupHandler(_repository);
        _controller = new CategoryGroupController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithCategoryGroups()
    {
        var groups = new List<CategoryGroup>
        {
            new("Espacios Académicos")
        };
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(groups);

        var result = await _controller.GetAll(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<CategoryGroupDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var id = Guid.NewGuid();
        var group = new CategoryGroup("Espacios Académicos");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns(group);

        var result = await _controller.GetById(id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dto = Assert.IsType<CategoryGroupDto>(okResult.Value);
        Assert.Equal("Espacios Académicos", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CategoryGroup?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryGroupDto("");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameExceeds100Characters_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryGroupDto(new string('G', 101));

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var request = new CreateCategoryGroupDto("Servicios");

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<CategoryGroupDto>(created.Value);
        Assert.Equal("Servicios", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateCategoryGroupDto("");

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNameExceeds100Characters_ShouldReturnBadRequest()
    {
        var request = new UpdateCategoryGroupDto(new string('G', 101));

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CategoryGroup?)null);

        var request = new UpdateCategoryGroupDto("Nuevo Nombre");

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var group = new CategoryGroup("Viejo");
        _repository.GetByIdAsync(group.Id, Arg.Any<CancellationToken>()).Returns(group);

        var request = new UpdateCategoryGroupDto("Nuevo");

        var result = await _controller.Update(group.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal("Nuevo", group.Name);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((CategoryGroup?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Delete_WhenValid_ShouldReturnNoContent()
    {
        var group = new CategoryGroup("Para borrar");
        _repository.GetByIdAsync(group.Id, Arg.Any<CancellationToken>()).Returns(group);

        var result = await _controller.Delete(group.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
