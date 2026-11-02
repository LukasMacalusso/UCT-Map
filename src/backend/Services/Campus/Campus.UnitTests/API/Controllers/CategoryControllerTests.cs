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

public class CategoryControllerTests
{
    private readonly IGenericRepository<Category> _repository;
    private readonly IGenericRepository<CategoryGroup> _groupRepository;
    private readonly CategoryHandler _handler;
    private readonly CategoryController _controller;

    public CategoryControllerTests()
    {
        _repository = Substitute.For<IGenericRepository<Category>>();
        _groupRepository = Substitute.For<IGenericRepository<CategoryGroup>>();
        _handler = new CategoryHandler(_repository, _groupRepository);
        _controller = new CategoryController(_handler);
    }

    [Fact]
    public async Task GetAll_ShouldReturnOkWithCategories()
    {
        var categories = new List<Category>
        {
            new("Aulas", "icon", "desc", Guid.NewGuid())
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
        var category = new Category("Laboratorio", "lab", "desc", Guid.NewGuid());
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
        var request = new CreateCategoryDto(Guid.NewGuid(), "", "icon", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenValid_ShouldReturnCreatedAtAction()
    {
        var groupId = Guid.NewGuid();
        _groupRepository.ExistsAsync(Arg.Any<Expression<Func<CategoryGroup, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        var request = new CreateCategoryDto(groupId, "Oficinas", "office", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var dto = Assert.IsType<CategoryDto>(created.Value);
        Assert.Equal("Oficinas", dto.Name);
    }

    [Fact]
    public async Task Update_WhenNameIsEmpty_ShouldReturnBadRequest()
    {
        var request = new UpdateCategoryDto(Guid.NewGuid(), "   ", "icon", "desc");

        var result = await _controller.Update(Guid.NewGuid(), request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenNotFound_ShouldReturnNotFound()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>()).Returns((Category?)null);

        var request = new UpdateCategoryDto(Guid.NewGuid(), "Nueva", "icon", "desc");

        var result = await _controller.Update(id, request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task Update_WhenValid_ShouldReturnNoContent()
    {
        var groupId = Guid.NewGuid();
        var category = new Category("Vieja", "icon", "desc", groupId);
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);
        _groupRepository.ExistsAsync(Arg.Any<Expression<Func<CategoryGroup, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateCategoryDto(groupId, "Nueva", "new-icon", "new-desc");

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
        var category = new Category("Para borrar", "icon", "desc", Guid.NewGuid());
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);

        var result = await _controller.Delete(category.Id, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task Delete_WhenDbConstraintViolated_ShouldReturnConflict409()
    {
        var category = new Category("Para borrar", "icon", "desc", Guid.NewGuid());
        _repository.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);
        _repository.When(r => r.SaveChangesAsync(Arg.Any<CancellationToken>()))
            .Do(_ => throw new Microsoft.EntityFrameworkCore.DbUpdateException("FK violation"));

        var result = await _controller.Delete(category.Id, CancellationToken.None);

        var objResult = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status409Conflict, objResult.StatusCode);
    }

    [Fact]
    public async Task Create_WhenCategoryGroupIdIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto(Guid.Empty, "Aula", "book", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenNameExceeds100Characters_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto(Guid.NewGuid(), new string('A', 101), "book", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenIconIsEmpty_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto(Guid.NewGuid(), "Aula", "", "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenIconExceeds100Characters_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto(Guid.NewGuid(), "Aula", new string('I', 101), "desc");

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Create_WhenDescriptionExceeds250Characters_ShouldReturnBadRequest()
    {
        var request = new CreateCategoryDto(Guid.NewGuid(), "Aula", "book", new string('D', 251));

        var result = await _controller.Create(request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result.Result);
    }

    [Fact]
    public async Task Reorder_WhenItemsEmpty_ShouldReturnBadRequest()
    {
        var result = await _controller.Reorder(new List<ReorderItemDto>(), CancellationToken.None);
        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Reorder_WhenValid_ShouldReturnNoContent()
    {
        var cat1 = new Category("C1", "i1", "d1", Guid.NewGuid(), 0);
        var cat2 = new Category("C2", "i2", "d2", Guid.NewGuid(), 1);
        _repository.GetAllAsync(Arg.Any<System.Linq.Expressions.Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1, cat2 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(cat2.Id, 10)
        };

        var result = await _controller.Reorder(items, CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        Assert.Equal(5, cat1.Order);
        Assert.Equal(10, cat2.Order);
    }

    [Fact]
    public async Task Reorder_WhenSomeNotFound_ShouldReturnBadRequest()
    {
        var cat1 = new Category("C1", "i1", "d1", Guid.NewGuid(), 0);
        _repository.GetAllAsync(Arg.Any<System.Linq.Expressions.Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(Guid.NewGuid(), 10)
        };

        var result = await _controller.Reorder(items, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }
}
