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
using Campus.Domain.ValueObjects;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.Application.Handlers;

public class StructureHandlerTests
{
    private readonly IGenericRepository<Structure> _repository;
    private readonly IGenericRepository<CampusEntity> _campusRepository;
    private readonly IGenericRepository<Category> _categoryRepository;
    private readonly StructureHandler _handler;

    public StructureHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Structure>>();
        _campusRepository = Substitute.For<IGenericRepository<CampusEntity>>();
        _categoryRepository = Substitute.For<IGenericRepository<Category>>();
        _handler = new StructureHandler(_repository, _campusRepository, _categoryRepository);
    }

    [Fact]
    public async Task GetAllAsync_ShouldFilterByPredicate()
    {
        var campusId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var structures = new List<Structure>
        {
            new("Pérgola", new Coordinate(-38.7, -72.5), campusId, categoryId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Structure, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(structures);

        var result = await _handler.GetAllAsync(campusId, categoryId, CancellationToken.None);

        var structure = Assert.Single(result);
        Assert.Equal("Pérgola", structure.Name);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var structure = new Structure("Cancha de Fútbol", new Coordinate(-38.7, -72.5), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>())
            .Returns(structure);

        var result = await _handler.GetByIdAsync(structure.Id, CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("Cancha de Fútbol", result.Name);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Structure?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.Null(result);
    }

    [Fact]
    public async Task CreateAsync_WhenCampusNotFound_ShouldReturnError()
    {
        var request = new CreateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Estacionamiento", -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var (dto, error) = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.Null(dto);
        Assert.NotNull(error);
        Assert.Contains("campus", error.ToLower());
    }

    [Fact]
    public async Task CreateAsync_WhenCategoryNotFound_ShouldReturnError()
    {
        var request = new CreateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Estacionamiento", -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var (dto, error) = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.Null(dto);
        Assert.NotNull(error);
        Assert.Contains("categoría", error.ToLower());
    }

    [Fact]
    public async Task CreateAsync_WhenValid_ShouldPersistAndReturnDto()
    {
        var campusId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var request = new CreateStructureDto(campusId, categoryId, "Estacionamiento", -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var (dto, error) = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.NotNull(dto);
        Assert.Null(error);
        Assert.Equal("Estacionamiento", dto.Name);
        Assert.Equal(campusId, dto.CampusId);
        Assert.Equal(categoryId, dto.CategoryId);

        await _repository.Received(1).AddAsync(Arg.Is<Structure>(s => s.Name == "Estacionamiento"), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenStructureNotFound_ShouldReturnFalseWithNullError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Structure?)null);

        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Nuevo", 0, 0);

        var (success, error) = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.False(success);
        Assert.Null(error);
    }

    [Fact]
    public async Task UpdateAsync_WhenCampusNotFound_ShouldReturnFalseWithError()
    {
        var structure = new Structure("Viejo", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>())
            .Returns(structure);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Nuevo", 0, 0);

        var (success, error) = await _handler.UpdateAsync(structure.Id, request, CancellationToken.None);

        Assert.False(success);
        Assert.NotNull(error);
        Assert.Contains("campus", error.ToLower());
    }

    [Fact]
    public async Task UpdateAsync_WhenCategoryNotFound_ShouldReturnFalseWithError()
    {
        var structure = new Structure("Viejo", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>())
            .Returns(structure);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateStructureDto(Guid.NewGuid(), Guid.NewGuid(), "Nuevo", 0, 0);

        var (success, error) = await _handler.UpdateAsync(structure.Id, request, CancellationToken.None);

        Assert.False(success);
        Assert.NotNull(error);
        Assert.Contains("categoría", error.ToLower());
    }

    [Fact]
    public async Task UpdateAsync_WhenValid_ShouldUpdateAndReturnTrue()
    {
        var campusId = Guid.NewGuid();
        var categoryId = Guid.NewGuid();
        var structure = new Structure("Viejo", new Coordinate(0, 0), campusId, categoryId);
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>())
            .Returns(structure);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        _categoryRepository.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateStructureDto(campusId, categoryId, "Actualizado", 10, 20);

        var (success, error) = await _handler.UpdateAsync(structure.Id, request, CancellationToken.None);

        Assert.True(success);
        Assert.Null(error);
        Assert.Equal("Actualizado", structure.Name);
        _repository.Received(1).Update(structure);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnFalse()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Structure?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.False(result);
    }

    [Fact]
    public async Task DeleteAsync_WhenFound_ShouldDeleteAndReturnTrue()
    {
        var structure = new Structure("Para borrar", new Coordinate(0, 0), Guid.NewGuid(), Guid.NewGuid());
        _repository.GetByIdAsync(structure.Id, Arg.Any<CancellationToken>())
            .Returns(structure);

        var result = await _handler.DeleteAsync(structure.Id, CancellationToken.None);

        Assert.True(result);
        _repository.Received(1).Delete(structure);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetAllLocationsAsync_WhenEmpty_ShouldReturnEmptyWithoutQueryingCategories()
    {
        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(Array.Empty<Structure>());

        var result = await _handler.GetAllLocationsAsync(null, null, CancellationToken.None);

        Assert.Empty(result);
        await _categoryRepository.DidNotReceive().GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetAllLocationsAsync_ShouldMapCategoryNameAndIconAndHandleMissingCategory()
    {
        var campusId = Guid.NewGuid();
        var category = new Category("Sala de Estudio", "users", "Espacio común", Guid.NewGuid());
        var missingCategoryId = Guid.NewGuid();

        var structures = new List<Structure>
        {
            new("Punto Estudio", new Coordinate(-38.73, -72.60), campusId, category.Id),
            new("Banca", new Coordinate(-38.74, -72.61), campusId, missingCategoryId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Structure, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(structures);
        _categoryRepository.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { category });

        var result = (await _handler.GetAllLocationsAsync(campusId, null, CancellationToken.None)).ToList();

        Assert.Equal(2, result.Count);
        Assert.Equal("Sala de Estudio", result[0].Metadata.CategoryName);
        Assert.Equal("users", result[0].Metadata.CategoryIcon);
        Assert.Equal(string.Empty, result[1].Metadata.CategoryName);
        Assert.Equal(string.Empty, result[1].Metadata.CategoryIcon);
    }

    [Fact]
    public async Task GetAllAsync_WithOnlyCategoryId_ShouldFilterByCategoryPredicate()
    {
        var categoryId = Guid.NewGuid();
        var structures = new List<Structure>
        {
            new("Cancha", new Coordinate(-38.7, -72.5), Guid.NewGuid(), categoryId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Structure, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(structures);

        var result = await _handler.GetAllAsync(null, categoryId, CancellationToken.None);

        Assert.Single(result);
    }
}
