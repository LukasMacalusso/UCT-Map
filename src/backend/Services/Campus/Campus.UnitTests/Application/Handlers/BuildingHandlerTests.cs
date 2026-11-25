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
using ErrorOr;
using NSubstitute;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.Application.Handlers;

public class BuildingHandlerTests
{
    private readonly IGenericRepository<Building> _repository;
    private readonly IGenericRepository<CampusEntity> _campusRepository;
    private readonly BuildingHandler _handler;

    public BuildingHandlerTests()
    {
        _repository = Substitute.For<IGenericRepository<Building>>();
        _campusRepository = Substitute.For<IGenericRepository<CampusEntity>>();
        _handler = new BuildingHandler(_repository, _campusRepository);
    }

    [Fact]
    public async Task GetAllAsync_WithoutFilter_ShouldReturnAllBuildings()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(-38.7, -72.5), campusId),
            new("Edificio B", 4, new Coordinate(-38.8, -72.6), campusId)
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = await _handler.GetAllAsync(null, CancellationToken.None);

        var list = result.ToList();
        Assert.Equal(2, list.Count);
        Assert.Equal("Edificio A", list[0].Name);
    }

    [Fact]
    public async Task GetAllAsync_WithCampusId_ShouldPassPredicate()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new("Edificio A", 3, new Coordinate(-38.7, -72.5), campusId)
        };

        _repository.GetAllAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = await _handler.GetAllAsync(campusId, CancellationToken.None);

        Assert.Single(result);
    }

    [Fact]
    public async Task GetAllLocationsAsync_ShouldReturnLocationsDto()
    {
        var campusId = Guid.NewGuid();
        var buildings = new List<Building>
        {
            new(
                "Edificio Central",
                5,
                new Coordinate(-38.73, -72.59),
                campusId,
                openTime: new TimeOnly(8, 0),
                closeTime: new TimeOnly(20, 30)
            ),
            new(
                "Edificio Abierto",
                2,
                new Coordinate(-38.74, -72.60),
                campusId,
                openTime: new TimeOnly(7, 30),
                closeTime: null
            ),
            new(
                "Edificio Cierre",
                1,
                new Coordinate(-38.75, -72.61),
                campusId,
                openTime: null,
                closeTime: new TimeOnly(22, 0)
            ),
            new(
                "Edificio Sin Horario",
                3,
                new Coordinate(-38.76, -72.62),
                campusId
            )
        };

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>())
            .Returns(buildings);

        var result = (await _handler.GetAllLocationsAsync(null, CancellationToken.None)).ToList();

        Assert.Equal(4, result.Count);

        Assert.Equal("Edificio Central", result[0].Name);
        Assert.Equal(-38.73, result[0].Location.Latitude);
        Assert.Equal(-72.59, result[0].Location.Longitude);
        Assert.Equal(campusId, result[0].Metadata.CampusId);
        Assert.Equal(5, result[0].Metadata.FloorsCount);
        Assert.Equal("08:00 - 20:30", result[0].Metadata.Schedule);

        Assert.Equal("07:30", result[1].Metadata.Schedule);
        Assert.Equal("22:00", result[2].Metadata.Schedule);
        Assert.Null(result[3].Metadata.Schedule);
    }

    [Fact]
    public async Task GetByIdAsync_WhenExists_ShouldReturnDto()
    {
        var building = new Building("Edificio A", 3, new Coordinate(-38.7, -72.5), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        var result = await _handler.GetByIdAsync(building.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Edificio A", result.Value.Name);
        Assert.Equal(3, result.Value.FloorsCount);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var result = await _handler.GetByIdAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task CreateAsync_WhenCampusNotFound_ShouldReturnCampusNotFoundError()
    {
        var campusId = Guid.NewGuid();
        var request = new CreateBuildingDto(campusId, "Edificio C", 2, -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Campus.NotFound", result.FirstError.Code);
        await _repository.DidNotReceive().AddAsync(Arg.Any<Building>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task CreateAsync_WhenValid_ShouldPersistAndReturnDto()
    {
        var campusId = Guid.NewGuid();
        var request = new CreateBuildingDto(campusId, "Edificio C", 2, -38.7, -72.5);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var result = await _handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("Edificio C", result.Value.Name);
        Assert.Equal(2, result.Value.FloorsCount);
        Assert.Equal(campusId, result.Value.CampusId);

        await _repository.Received(1).AddAsync(Arg.Is<Building>(b => b.Name == "Edificio C"), Arg.Any<CancellationToken>());
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_WhenBuildingNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var request = new UpdateBuildingDto(Guid.NewGuid(), "Nuevo", 3, 0, 0);

        var result = await _handler.UpdateAsync(id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenCampusNotFound_ShouldReturnCampusNotFoundError()
    {
        var building = new Building("Antiguo", 1, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(false);

        var request = new UpdateBuildingDto(Guid.NewGuid(), "Nuevo", 3, 0, 0);

        var result = await _handler.UpdateAsync(building.Id, request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Campus.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateAsync_WhenValid_ShouldUpdateAndReturnSuccess()
    {
        var campusId = Guid.NewGuid();
        var building = new Building("Antiguo", 1, new Coordinate(0, 0), campusId);
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);

        var request = new UpdateBuildingDto(campusId, "Nuevo Nombre", 4, 10, 20);

        var result = await _handler.UpdateAsync(building.Id, request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        Assert.Equal("Nuevo Nombre", building.Name);
        Assert.Equal(4, building.FloorsCount);
        _repository.Received(1).Update(building);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task DeleteAsync_WhenNotFound_ShouldReturnNotFoundError()
    {
        var id = Guid.NewGuid();
        _repository.GetByIdAsync(id, Arg.Any<CancellationToken>())
            .Returns((Building?)null);

        var result = await _handler.DeleteAsync(id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal("Building.NotFound", result.FirstError.Code);
    }

    [Fact]
    public async Task DeleteAsync_WhenFound_ShouldDeleteAndReturnSuccess()
    {
        var building = new Building("Para Borrar", 1, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>())
            .Returns(building);

        var result = await _handler.DeleteAsync(building.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        _repository.Received(1).Delete(building);
        await _repository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task GetAllLocationsAsync_ShouldIncludeCategoryMetadataAndPhotoUrl()
    {
        var categoryRepo = Substitute.For<IGenericRepository<Category>>();
        var handler = new BuildingHandler(_repository, _campusRepository, categoryRepo);
        var category = new Category("Edificio Docente", "school", "Docencia", 1);
        var building = new Building("Edificio A", 4, new Coordinate(-38.73, -72.59), Guid.NewGuid(), TimeOnly.Parse("08:00"), TimeOnly.Parse("20:00"), category.Id, "https://uct.cl/edificio-a.jpg");

        _repository.GetAllAsync(Arg.Any<Expression<Func<Building, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Building> { building });
        categoryRepo.GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(new List<Category> { category });

        var result = (await handler.GetAllLocationsAsync(null, CancellationToken.None)).ToList();

        var dto = Assert.Single(result);
        Assert.Equal(category.Id, dto.CategoryId);
        Assert.Equal("Edificio Docente", dto.Metadata.CategoryName);
        Assert.Equal("school", dto.Metadata.CategoryIcon);
        Assert.Equal("https://uct.cl/edificio-a.jpg", dto.Metadata.PhotoUrl);
    }

    [Fact]
    public async Task CreateAsync_WithCategoryAndPhotoUrl_ShouldPersistAndReturnFullDto()
    {
        var categoryRepo = Substitute.For<IGenericRepository<Category>>();
        var handler = new BuildingHandler(_repository, _campusRepository, categoryRepo);
        var campusId = Guid.NewGuid();
        var category = new Category("Biblioteca", "book", "Biblioteca Central", 2);
        var request = new CreateBuildingDto(campusId, "Biblioteca", 3, -38.73, -72.59, null, null, category.Id, "https://uct.cl/biblio.jpg");

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>())
            .Returns(true);
        categoryRepo.GetByIdAsync(category.Id, Arg.Any<CancellationToken>())
            .Returns(category);

        var result = await handler.CreateAsync(request, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal("https://uct.cl/biblio.jpg", result.Value.PhotoUrl);
        Assert.Equal("Biblioteca", result.Value.CategoryName);
        Assert.Equal("book", result.Value.CategoryIcon);
    }

    [Fact]
    public async Task DeleteAsync_WhenBuildingHasRooms_ShouldReturnConflict()
    {
        var roomRepo = Substitute.For<IGenericRepository<Room>>();
        var handler = new BuildingHandler(_repository, _campusRepository, roomRepository: roomRepo);
        var building = new Building("Edificio Con Salas", 2, new Coordinate(0, 0), Guid.NewGuid());

        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);
        roomRepo.ExistsAsync(Arg.Any<Expression<Func<Room, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);

        var result = await handler.DeleteAsync(building.Id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Equal("Building.HasRooms", result.FirstError.Code);
        _repository.DidNotReceive().Delete(Arg.Any<Building>());
    }

    private sealed class DbUpdateException(string message) : Exception(message);

    [Fact]
    public async Task DeleteAsync_WhenDbUpdateExceptionOccurs_ShouldReturnConflictError()
    {
        var building = new Building("Edificio Restringido", 2, new Coordinate(0, 0), Guid.NewGuid());
        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);
        _repository.When(r => r.SaveChangesAsync(Arg.Any<CancellationToken>()))
            .Do(_ => throw new DbUpdateException("FK constraint"));

        var result = await _handler.DeleteAsync(building.Id, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.Equal("Building.Conflict", result.FirstError.Code);
    }

    [Fact]
    public async Task GetByIdAsync_WithCategoryRepository_ShouldPopulateCategoryMetadata()
    {
        var categoryRepo = Substitute.For<IGenericRepository<Category>>();
        var handler = new BuildingHandler(_repository, _campusRepository, categoryRepo);
        var category = new Category("Laboratorio", "flask", "Ciencias", 1);
        var building = new Building("Edificio Ciencias", 3, new Coordinate(-38.73, -72.59), Guid.NewGuid(), new TimeOnly(8, 0), new TimeOnly(19, 0), category.Id, "https://uct.cl/ciencias.jpg");

        _repository.GetByIdAsync(building.Id, Arg.Any<CancellationToken>()).Returns(building);
        categoryRepo.GetByIdAsync(category.Id, Arg.Any<CancellationToken>()).Returns(category);

        var result = await handler.GetByIdAsync(building.Id, CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(-38.73, result.Value.Latitude);
        Assert.Equal(-72.59, result.Value.Longitude);
        Assert.Equal(category.Id, result.Value.CategoryId);
        Assert.Equal(new TimeOnly(8, 0), result.Value.OpenTime);
        Assert.Equal(new TimeOnly(19, 0), result.Value.CloseTime);
        Assert.Equal("Laboratorio", result.Value.CategoryName);
        Assert.Equal("flask", result.Value.CategoryIcon);
    }

    [Fact]
    public async Task GetAllAsync_WithCategoryRepoAndUncategorizedBuildings_ShouldSkipCategoryQuery()
    {
        var categoryRepo = Substitute.For<IGenericRepository<Category>>();
        var handler = new BuildingHandler(_repository, _campusRepository, categoryRepo);
        var building = new Building("Edificio Sin Cat", 2, new Coordinate(0, 0), Guid.NewGuid());

        _repository.GetAllAsync(null, Arg.Any<CancellationToken>()).Returns(new List<Building> { building });

        var result = (await handler.GetAllAsync(null, null, CancellationToken.None)).ToList();

        Assert.Single(result);
        await categoryRepo.DidNotReceive().GetAllAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task CreateAndUpdateAsync_WithInvalidOrMissingCategory_ShouldReturnCategoryNotFound()
    {
        var categoryRepo = Substitute.For<IGenericRepository<Category>>();
        var handler = new BuildingHandler(_repository, _campusRepository, categoryRepo);
        var campusId = Guid.NewGuid();
        var missingCategoryId = Guid.NewGuid();
        var validCategoryId = Guid.NewGuid();
        var existingBuilding = new Building("Existente", 2, new Coordinate(0, 0), campusId);

        _campusRepository.ExistsAsync(Arg.Any<Expression<Func<CampusEntity, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        _repository.GetByIdAsync(existingBuilding.Id, Arg.Any<CancellationToken>()).Returns(existingBuilding);
        categoryRepo.GetByIdAsync(missingCategoryId, Arg.Any<CancellationToken>()).Returns((Category?)null);
        categoryRepo.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(false);

        var createEmptyCat = await handler.CreateAsync(new CreateBuildingDto(campusId, "B1", 2, 0, 0, null, null, Guid.Empty), CancellationToken.None);
        var createMissingCat = await handler.CreateAsync(new CreateBuildingDto(campusId, "B2", 2, 0, 0, null, null, missingCategoryId), CancellationToken.None);
        var updateEmptyCat = await handler.UpdateAsync(existingBuilding.Id, new UpdateBuildingDto(campusId, "B3", 2, 0, 0, null, null, Guid.Empty), CancellationToken.None);
        var updateMissingCat = await handler.UpdateAsync(existingBuilding.Id, new UpdateBuildingDto(campusId, "B4", 2, 0, 0, null, null, missingCategoryId), CancellationToken.None);

        Assert.Equal("Category.NotFound", createEmptyCat.FirstError.Code);
        Assert.Equal("Category.NotFound", createMissingCat.FirstError.Code);
        Assert.Equal("Category.NotFound", updateEmptyCat.FirstError.Code);
        Assert.Equal("Category.NotFound", updateMissingCat.FirstError.Code);

        categoryRepo.ExistsAsync(Arg.Any<Expression<Func<Category, bool>>>(), Arg.Any<CancellationToken>()).Returns(true);
        var updateValidCat = await handler.UpdateAsync(existingBuilding.Id, new UpdateBuildingDto(campusId, "B5", 3, 0, 0, null, null, validCategoryId), CancellationToken.None);
        Assert.False(updateValidCat.IsError);
    }
}
