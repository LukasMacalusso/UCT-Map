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
using NSubstitute;
using Xunit;

namespace Campus.UnitTests.Application.Handlers;

public class CategoryHandlerTests
{
    private readonly IGenericRepository<Category> _repository;
    private readonly IGenericRepository<CategoryGroup> _groupRepository;
    private readonly CategoryHandler _handler;

    public CategoryHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Category>>();
        _groupRepository = Substitute.For<IGenericRepository<CategoryGroup>>();
        _handler = new CategoryHandler(_repository, _groupRepository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnMappedCategories()
    {
        var groupId = Guid.NewGuid();
        var categories = new List<Category>
        {
            new("Salas", "room-icon", "Salas de clases", groupId),
            new("Laboratorios", "lab-icon", "Laboratorios", groupId)
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(categories);

        var result = await _handler.GetAllAsync(CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Salas", list[0].Name);
        Assert.Equal("room-icon", list[0].Icon);
        Assert.Equal(groupId, list[0].CategoryGroupId);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var id = Guid.NewGuid();
        var groupId = Guid.NewGuid();
        var category = new Category("Auditorios", "aud-icon", "Auditorios", groupId);
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("Auditorios", result.Name);
        Assert.Equal("aud-icon", result.Icon);
        Assert.Equal(groupId, result.CategoryGroupId);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task CreateAsync_ShouldPersistAndReturnDto()
    {
        var groupId = Guid.NewGuid();
        _groupRepository.ExistsAsync(Arg.Any<Expression<Func<CategoryGroup, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new CreateCategoryDto(groupId, "Cafeterías", "cafe-icon", "Puntos de comida");

        var (result, error) = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.Null(error);
        Assert.NotNull(result);
        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Cafeterías", result.Name);
        Assert.Equal("cafe-icon", result.Icon);
        Assert.Equal("Puntos de comida", result.Description);
        Assert.Equal(groupId, result.CategoryGroupId);

        await _repository.Received(1).AddAsync(Arg.Is<Category>(c => c.Name == request.Name), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task CreateAsync_WhenGroupDoesNotExist_ShouldReturnError()
    {
        var groupId = Guid.NewGuid();
        _groupRepository.ExistsAsync(Arg.Any<Expression<Func<CategoryGroup, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new CreateCategoryDto(groupId, "Cafeterías", "cafe-icon", "Puntos de comida");

        var (result, error) = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.Null(result);
        Assert.NotNull(error);
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_ShouldUpdateAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var groupId = Guid.NewGuid();
        var category = new Category("Antiguo", "old-icon", "Desc", groupId);
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);
        _groupRepository.ExistsAsync(Arg.Any<Expression<Func<CategoryGroup, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateCategoryDto(groupId, "Nuevo", "new-icon", "Nueva Desc");

        var (success, error) = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(success);
        Assert.Null(error);
        Assert.Equal("Nuevo", category.Name);
        Assert.Equal("new-icon", category.Icon);
        _repository.Received(1).Update(category);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var request = new UpdateCategoryDto(Guid.NewGuid(), "Nuevo", "new-icon", "Nueva Desc");

        var (success, error) = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.False(success);
        Assert.Null(error);
        _repository.DidNotReceive().Update(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_ShouldDeleteAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var category = new Category("Por borrar", "icon", "desc", Guid.NewGuid());
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var (success, error, notFound) = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(success);
        Assert.False(notFound);
        Assert.Null(error);
        _repository.Received(1).Delete(category);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var (success, error, notFound) = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(success);
        Assert.True(notFound);
        _repository.DidNotReceive().Delete(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenDbUpdateExceptionOccurs_ShouldReturnConflictError()
    {
        var id = Guid.NewGuid();
        var category = new Category("Por borrar", "icon", "desc", Guid.NewGuid());
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);
        _repository.When(r => r.SaveChangesAsync(Arg.Any<CancellationToken>()))
            .Do(_ => throw new Microsoft.EntityFrameworkCore.DbUpdateException("FK conflict"));

        var (success, error, notFound) = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(success);
        Assert.False(notFound);
        Assert.NotNull(error);
    }

    [Fact]
    public async Task ReorderAsync_WhenAllCategoriesExist_ShouldUpdateOrdersAndReturnTrue()
    {
        var groupId = Guid.NewGuid();
        var cat1 = new Category("Cat 1", "icon1", "desc1", groupId, 0);
        var cat2 = new Category("Cat 2", "icon2", "desc2", groupId, 1);

        _repository.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1, cat2 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(cat2.Id, 10)
        };

        var result = await _handler.ReorderAsync(items, CancellationToken.None);

        Assert.True(result);
        Assert.Equal(5, cat1.Order);
        Assert.Equal(10, cat2.Order);
        _repository.Received(1).Update(cat1);
        _repository.Received(1).Update(cat2);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ReorderAsync_WhenSomeCategoryNotFound_ShouldReturnFalse()
    {
        var cat1 = new Category("Cat 1", "icon1", "desc1", Guid.NewGuid(), 0);

        _repository.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { cat1 });

        var items = new List<ReorderItemDto>
        {
            new(cat1.Id, 5),
            new(Guid.NewGuid(), 10)
        };

        var result = await _handler.ReorderAsync(items, CancellationToken.None);

        Assert.False(result);
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
