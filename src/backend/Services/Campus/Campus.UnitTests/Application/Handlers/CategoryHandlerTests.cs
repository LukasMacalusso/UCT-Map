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
using ErrorOr;
using NSubstitute;
using Xunit;

namespace Campus.UnitTests.Application.Handlers;

public class CategoryHandlerTests
{
    private readonly IGenericRepository<Category> _repository;
    private readonly CategoryHandler _handler;

    public CategoryHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Category>>();
        _handler = new CategoryHandler(_repository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnMappedAndOrderedCategories()
    {
        var categories = new List<Category>
        {
            new("Laboratorios", "lab-icon", "Laboratorios", 2),
            new("Salas", "room-icon", "Salas de clases", 1)
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(categories);

        var result = await _handler.GetAllAsync(CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Salas", list[0].Name);
        Assert.Equal("room-icon", list[0].Icon);
        Assert.Equal(1, list[0].Order);
        Assert.Equal("Laboratorios", list[1].Name);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var id = Guid.NewGuid();
        var category = new Category("Auditorios", "aud-icon", "Auditorios", 1);
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Auditorios", result.Value.Name);
        Assert.Equal("aud-icon", result.Value.Icon);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        Assert.Equal("Category.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_ShouldPersistAndReturnDto()
    {
        var request = new CreateCategoryDto("Cafeterías", "cafe-icon", "Puntos de comida", 3);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.NotEqual(Guid.Empty, result.Value.Id);
        Assert.Equal("Cafeterías", result.Value.Name);
        Assert.Equal("cafe-icon", result.Value.Icon);
        Assert.Equal("Puntos de comida", result.Value.Description);
        Assert.Equal(3, result.Value.Order);

        await _repository.Received(1).AddAsync(Arg.Is<Category>(c => c.Name == request.Name), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_ShouldUpdateAndReturnSuccess()
    {
        var id = Guid.NewGuid();
        var category = new Category("Antiguo", "old-icon", "Desc", 1);
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var request = new UpdateCategoryDto("Nuevo", "new-icon", "Nueva Desc", 4);

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Nuevo", category.Name);
        Assert.Equal("new-icon", category.Icon);
        Assert.Equal("Nueva Desc", category.Description);
        Assert.Equal(4, category.Order);
        _repository.Received(1).Update(category);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var request = new UpdateCategoryDto("Nuevo", "new-icon", "Nueva Desc");

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        _repository.DidNotReceive().Update(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_ShouldDeleteAndReturnSuccess()
    {
        var id = Guid.NewGuid();
        var category = new Category("Por borrar", "icon", "desc");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(result.IsError);
        _repository.Received(1).Delete(category);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        _repository.DidNotReceive().Delete(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenDbUpdateExceptionOccurs_ShouldReturnConflictError()
    {
        var id = Guid.NewGuid();
        var category = new Category("Por borrar", "icon", "desc");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);
        _repository.When(r => r.SaveChangesAsync(Arg.Any<CancellationToken>()))
            .Do(_ => throw new Microsoft.EntityFrameworkCore.DbUpdateException("FK conflict"));

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Equal("Category.Conflict", result.FirstError.Code);
    }

    [Fact]
    public async Task ReorderAsync_WhenListIsEmpty_ShouldReturnSuccessWithoutSaving()
    {
        var result = await _handler.ReorderAsync(Array.Empty<ReorderItemDto>(), CancellationToken.None);

        Assert.False(result.IsError);
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ReorderAsync_WhenAllCategoriesExist_ShouldUpdateOrdersAndReturnSuccess()
    {
        var cat1 = new Category("Cat 1", "icon1", "desc1", 0);
        var cat2 = new Category("Cat 2", "icon2", "desc2", 1);

        _repository.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1, cat2 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(cat2.Id, 10)
        };

        var result = await _handler.ReorderAsync(items, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(5, cat1.Order);
        Assert.Equal(10, cat2.Order);
        _repository.Received(1).Update(cat1);
        _repository.Received(1).Update(cat2);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ReorderAsync_WhenSomeCategoryNotFound_ShouldReturnValidationError()
    {
        var cat1 = new Category("Cat 1", "icon1", "desc1", 0);

        _repository.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(Guid.NewGuid(), 10)
        };

        var result = await _handler.ReorderAsync(items, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
