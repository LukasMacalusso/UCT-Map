using System;
using System.Collections.Generic;
using System.Linq;
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
    private readonly CategoryHandler _handler;

    public CategoryHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Category>>();
        _handler = new CategoryHandler(_repository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldReturnMappedCategories()
    {
        var categories = new List<Category>
        {
            new("Salas", "room-icon", "Salas de clases"),
            new("Laboratorios", "lab-icon", "Laboratorios")
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(categories);

        var result = await _handler.GetAllAsync(CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Salas", list[0].Name);
        Assert.Equal("room-icon", list[0].Icon);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var id = Guid.NewGuid();
        var category = new Category("Auditorios", "aud-icon", "Auditorios");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("Auditorios", result.Name);
        Assert.Equal("aud-icon", result.Icon);
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
        var request = new CreateCategoryDto("Cafeterías", "cafe-icon", "Puntos de comida");

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.NotNull(result);
        Assert.NotEqual(Guid.Empty, result.Id);
        Assert.Equal("Cafeterías", result.Name);
        Assert.Equal("cafe-icon", result.Icon);
        Assert.Equal("Puntos de comida", result.Description);

        await _repository.Received(1).AddAsync(Arg.Is<Category>(c => c.Name == request.Name), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenExists_ShouldUpdateAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var category = new Category("Antiguo", "old-icon", "Desc");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var request = new UpdateCategoryDto("Nuevo", "new-icon", "Nueva Desc");

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result);
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

        var request = new UpdateCategoryDto("Nuevo", "new-icon", "Nueva Desc");

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.False(result);
        _repository.DidNotReceive().Update(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenExists_ShouldDeleteAndReturnTrue()
    {
        var id = Guid.NewGuid();
        var category = new Category("Por borrar", "icon", "desc");
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result);
        _repository.Received(1).Delete(category);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Category?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(result);
        _repository.DidNotReceive().Delete(Arg.Any<Category>());
        await _repository.DidNotReceive().SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
