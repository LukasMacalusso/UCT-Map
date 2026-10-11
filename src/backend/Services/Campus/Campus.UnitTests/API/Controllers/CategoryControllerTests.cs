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

public class CategoryControllerTests
{
    private readonly IGenericRepository<Category> _repository;
    private readonly CategoryHandler _handler;
    private readonly CategoryController _controller;

    public CategoryControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<Category>>();
        _handler = new CategoryHandler(_repository);
        _controller = new CategoryController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithCategories()
    {
        var categories = new List<Category>
        {
            new("Aulas", "icon", "desc")
        };
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(categories);

        var result = await _controller.GetAll(CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dtos = Assert.IsAssignableFrom<IEnumerable<CategoryDto>>(okResult.Value);
        Assert.Single(dtos);
    }

    [Fact]
    public async Task GetById_WhenFound_ShouldReturnOk()
    {
        var category = new Category("Laboratorio", "lab", "desc");
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);

        var result = await _controller.GetById(category.Id, CancellationToken.None);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var dto = Assert.IsType<CategoryDto>(okResult.Value);
        Assert.Equal("Laboratorio", dto.Name);
    }

    [Fact]
    public async Task GetById_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Category?)null);

        var result = await _controller.GetById(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto("", "icon", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var request = new CreateCategoryDto("Oficinas", "office", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<CategoryDto>(created.Value);
        Assert.Equal("Oficinas", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateCategoryDto("   ", "icon", "desc");

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Category?)null);

        var request = new UpdateCategoryDto("Nueva", "icon", "desc");

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var category = new Category("Vieja", "icon", "desc");
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);

        var request = new UpdateCategoryDto("Nueva", "new-icon", "new-desc");

        var result = await _controller.Update(category.Id, request, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Category?)null);

        var result = await _controller.Delete(id, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Delete_WhenValid_ShouldReturnNoContent()
    {
        var category = new Category("Para borrar", "icon", "desc");
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);

        var result = await _controller.Delete(category.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }
}
