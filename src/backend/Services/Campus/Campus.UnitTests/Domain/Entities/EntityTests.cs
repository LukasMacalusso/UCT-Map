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

        // Constructor with Campus instance
        var building1 = new Building("Edificio A", 4, coords, campus);
        Assert.NotEqual(Guid.Empty, building1.Id);
        Assert.Equal("Edificio A", building1.Name);
        Assert.Equal(4, building1.FloorsCount);
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
        building2.Update("Edificio Renovado", 5, newCoords, newCampusId);
        Assert.Equal("Edificio Renovado", building2.Name);
        Assert.Equal(5, building2.FloorsCount);
        Assert.Equal(newCoords, building2.Coordinates);
        Assert.Equal(newCampusId, building2.CampusId);
    }

    [Fact]
    public void Category_ShouldCreateAndInitializeProperly()
    {
        var category = new Category("Salas", "room-icon", "Salas de clases regulares");

        Assert.NotEqual(Guid.Empty, category.Id);
        Assert.Equal("Salas", category.Name);
        Assert.Equal("room-icon", category.Icon);
        Assert.Equal("Salas de clases regulares", category.Description);
        Assert.Empty(category.Rooms);
        Assert.Empty(category.Structures);

        category.Update("Laboratorios", "lab-icon", "Laboratorios de computación");
        Assert.Equal("Laboratorios", category.Name);
        Assert.Equal("lab-icon", category.Icon);
        Assert.Equal("Laboratorios de computación", category.Description);
    }

    [Fact]
    public void Room_ShouldCreateWithEntityInstancesAndWithGuids()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus Norte", "Dir 1", coords);
        var building = new Building("Edificio A", 3, coords, campus);
        var category = new Category("Auditorios", "aud-icon", "Auditorios");

        // Constructor with entities
        var room1 = new Room("Aula Magna", 1, "AM-101", building, category);
        Assert.NotEqual(Guid.Empty, room1.Id);
        Assert.Equal("Aula Magna", room1.Name);
        Assert.Equal(1, room1.Floor);
        Assert.Equal("AM-101", room1.Number);
        Assert.Equal(building.Id, room1.BuildingId);
        Assert.Equal(category.Id, room1.CategoryId);
        Assert.Equal(building, room1.Building);
        Assert.Equal(category, room1.Category);

        // Constructor with Guids
        var room2 = new Room("Sala 102", 2, "S-102", building.Id, category.Id);
        Assert.NotEqual(Guid.Empty, room2.Id);
        Assert.Equal("Sala 102", room2.Name);
        Assert.Equal(2, room2.Floor);
        Assert.Equal("S-102", room2.Number);

        // Update
        var newBuildingId = Guid.NewGuid();
        var newCatId = Guid.NewGuid();
        room2.Update("Sala 204", 3, null, newBuildingId, newCatId);
        Assert.Equal("Sala 204", room2.Name);
        Assert.Equal(3, room2.Floor);
        Assert.Null(room2.Number);
        Assert.Equal(newBuildingId, room2.BuildingId);
        Assert.Equal(newCatId, room2.CategoryId);
    }

    [Fact]
    public void Structure_ShouldCreateWithEntityInstancesAndWithGuids()
    {
        var coords = new Coordinate(-38.73, -72.59);
        var campus = new CampusEntity("Campus San Francisco", "Manuel Montt 056", coords);
        var category = new Category("Pérgolas", "icon-pergola", "Zonas de descanso");

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
