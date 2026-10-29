using System;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.UnitTests.Domain.Entities;

public class EntityTests
{
    [Fact]
    public void Coordinate_ShouldStoreLatitudeAndLongitude()
    {
        var coord = new Coordinate(-38.7369, -72.5901);
        Assert.Equal(-38.7369, coord.Latitude);
        Assert.Equal(-72.5901, coord.Longitude);

        var coordSame = new Coordinate(-38.7369, -72.5901);
        Assert.Equal(coord, coordSame);
    }

    [Fact]
    public void Campus_ShouldCreateAndInitializeProperly()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus San Juan Pablo II", "Rudecindo Ortega 02950", coords, 16.5m, 45.0m, 120.5m);

        Assert.NotEqual(Guid.Empty, campus.Id);
        Assert.Equal("Campus San Juan Pablo II", campus.Name);
        Assert.Equal("Rudecindo Ortega 02950", campus.Address);
        Assert.Equal(coords, campus.Coordinates);
        Assert.Equal(16.5m, campus.Zoom);
        Assert.Equal(45.0m, campus.Pitch);
        Assert.Equal(120.5m, campus.Bearing);
        Assert.Empty(campus.Buildings);
        Assert.Empty(campus.Structures);

        var newCoords = new Coordinate(-38.74, -72.60);
        campus.Update("Campus Norte", "Av. Alemania 0211", newCoords, 17.0m, 30.0m, 90.0m);

        Assert.Equal("Campus Norte", campus.Name);
        Assert.Equal("Av. Alemania 0211", campus.Address);
        Assert.Equal(newCoords, campus.Coordinates);
        Assert.Equal(17.0m, campus.Zoom);
        Assert.Equal(30.0m, campus.Pitch);
        Assert.Equal(90.0m, campus.Bearing);
    }

    [Fact]
    public void Building_ShouldCreateWithCampusIdAndWithCampusInstance()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus San Juan Pablo II", "Rudecindo Ortega 02950", coords);
        var openTime = new TimeOnly(8, 0);
        var closeTime = new TimeOnly(20, 0);

        // Constructor with Campus instance
        var building1 = new Building("Edificio A", 4, coords, campus, openTime, closeTime, "Cafetería, Wi-Fi");
        Assert.NotEqual(Guid.Empty, building1.Id);
        Assert.Equal("Edificio A", building1.Name);
        Assert.Equal(4, building1.FloorsCount);
        Assert.Equal(openTime, building1.OpenTime);
        Assert.Equal(closeTime, building1.CloseTime);
        Assert.Equal("Cafetería, Wi-Fi", building1.Services);
        Assert.Equal(campus.Id, building1.CampusId);
        Assert.Equal(campus, building1.Campus);
        Assert.Empty(building1.Rooms);

        // Constructor with Guid
        var building2 = new Building("Edificio B", 2, coords, campus.Id);
        Assert.NotEqual(Guid.Empty, building2.Id);
        Assert.Equal("Edificio B", building2.Name);
        Assert.Equal(2, building2.FloorsCount);
        Assert.Equal(campus.Id, building2.CampusId);

        // Update
        var newCampusId = Guid.NewGuid();
        var newCoords = new Coordinate(-38.75, -72.61);
        building2.Update("Edificio Renovado", 5, newCoords, newCampusId, new TimeOnly(9, 0), new TimeOnly(18, 0), "Biblioteca");
        Assert.Equal("Edificio Renovado", building2.Name);
        Assert.Equal(5, building2.FloorsCount);
        Assert.Equal(newCoords, building2.Coordinates);
        Assert.Equal(newCampusId, building2.CampusId);
        Assert.Equal(new TimeOnly(9, 0), building2.OpenTime);
        Assert.Equal(new TimeOnly(18, 0), building2.CloseTime);
        Assert.Equal("Biblioteca", building2.Services);
    }

    [Fact]
    public void CategoryGroup_ShouldCreateAndInitializeProperly()
    {
        var group = new CategoryGroup("Académico");
        Assert.NotEqual(Guid.Empty, group.Id);
        Assert.Equal("Académico", group.Name);
        Assert.Empty(group.Categories);

        group.Update("Servicios");
        Assert.Equal("Servicios", group.Name);
    }

    [Fact]
    public void Category_ShouldCreateAndInitializeProperly()
    {
        var group = new CategoryGroup("Académico");
        var category = new Category("Salas", "room-icon", "Salas de clases regulares", group);

        Assert.NotEqual(Guid.Empty, category.Id);
        Assert.Equal("Salas", category.Name);
        Assert.Equal("room-icon", category.Icon);
        Assert.Equal("Salas de clases regulares", category.Description);
        Assert.Equal(group.Id, category.CategoryGroupId);
        Assert.Equal(group, category.CategoryGroup);
        Assert.Empty(category.Rooms);
        Assert.Empty(category.Structures);

        var newGroupId = Guid.NewGuid();
        category.Update("Laboratorios", "lab-icon", "Laboratorios de computación", newGroupId);
        Assert.Equal("Laboratorios", category.Name);
        Assert.Equal("lab-icon", category.Icon);
        Assert.Equal("Laboratorios de computación", category.Description);
        Assert.Equal(newGroupId, category.CategoryGroupId);
    }

    [Fact]
    public void Room_ShouldCreateWithEntityInstancesAndWithGuids()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus Norte", "Dir 1", coords);
        var building = new Building("Edificio A", 3, coords, campus);
        var group = new CategoryGroup("Académico");
        var category = new Category("Auditorios", "aud-icon", "Auditorios", group);

        // Constructor with entities
        var room1 = new Room("AM-101", 1, building, category);
        Assert.NotEqual(Guid.Empty, room1.Id);
        Assert.Equal("AM-101", room1.Name);
        Assert.Equal(1, room1.Floor);
        Assert.Equal(building.Id, room1.BuildingId);
        Assert.Equal(category.Id, room1.CategoryId);
        Assert.Equal(building, room1.Building);
        Assert.Equal(category, room1.Category);

        // Constructor with Guids
        var room2 = new Room("S-102", 2, building.Id, category.Id);
        Assert.NotEqual(Guid.Empty, room2.Id);
        Assert.Equal("S-102", room2.Name);
        Assert.Equal(2, room2.Floor);

        // Update
        var newBuildingId = Guid.NewGuid();
        var newCatId = Guid.NewGuid();
        room2.Update("S-204", 3, newBuildingId, newCatId);
        Assert.Equal("S-204", room2.Name);
        Assert.Equal(3, room2.Floor);
        Assert.Equal(newBuildingId, room2.BuildingId);
        Assert.Equal(newCatId, room2.CategoryId);
    }

    [Fact]
    public void Structure_ShouldCreateWithEntityInstancesAndWithGuids()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus San Francisco", "Manuel Montt 056", coords);
        var group = new CategoryGroup("Recreación");
        var category = new Category("Pérgolas", "icon-pergola", "Zonas de descanso", group);

        // Constructor with entities
        var structure1 = new Structure("Pérgola Central", coords, campus, category);
        Assert.NotEqual(Guid.Empty, structure1.Id);
        Assert.Equal("Pérgola Central", structure1.Name);
        Assert.Equal(coords, structure1.Coordinates);
        Assert.Equal(campus.Id, structure1.CampusId);
        Assert.Equal(category.Id, structure1.CategoryId);
        Assert.Equal(campus, structure1.Campus);
        Assert.Equal(category, structure1.Category);

        // Constructor with Guids
        var structure2 = new Structure("Estacionamiento Norte", coords, campus.Id, category.Id);
        Assert.NotEqual(Guid.Empty, structure2.Id);
        Assert.Equal("Estacionamiento Norte", structure2.Name);

        // Update
        var newCoords = new Coordinate(-38.74, -72.60);
        var newCampusId = Guid.NewGuid();
        var newCatId = Guid.NewGuid();
        structure2.Update("Estacionamiento Sur", newCoords, newCampusId, newCatId);
        Assert.Equal("Estacionamiento Sur", structure2.Name);
        Assert.Equal(newCoords, structure2.Coordinates);
        Assert.Equal(newCampusId, structure2.CampusId);
        Assert.Equal(newCatId, structure2.CategoryId);
    }
}
