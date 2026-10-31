using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Microsoft.EntityFrameworkCore;
using CampusEntity = Campus.Domain.Entities.Campus;
using StructureEntity = Campus.Domain.Entities.Structure;

namespace Campus.Infrastructure.Persistence;

public static class CampusDbContextSeed
{
    public static async Task SeedAsync(CampusDbContext context)
    {
        if (await context.Campuses.AnyAsync())
        {
            return;
        }

        var grupoAcademico = new CategoryGroup("Espacios Académicos");
        var grupoComun = new CategoryGroup("Espacios Comunes");
        var grupoServicios = new CategoryGroup("Servicios");

        await context.CategoryGroups.AddRangeAsync(grupoAcademico, grupoComun, grupoServicios);

        var catSalaClases = new Category("Sala de Clases", "book", "Sala de uso general para clases teóricas", grupoAcademico);
        var catLaboratorio = new Category("Laboratorio", "computer", "Laboratorio de computación o ciencias", grupoAcademico);
        var catEstudio = new Category("Sala de Estudio", "users", "Espacio para estudio grupal o individual", grupoComun);

        await context.Categories.AddRangeAsync(catSalaClases, catLaboratorio, catEstudio);

        var campusSanFrancisco = new CampusEntity(
            "Campus San Francisco",
            "Manuel Montt 056, Temuco",
            new Coordinate(-38.7335, -72.6020),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        var campusSanJuanPablo = new CampusEntity(
            "Campus San Juan Pablo II",
            "Rudecindo Ortega 02950, Temuco",
            new Coordinate(-38.7118, -72.5855),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        await context.Campuses.AddRangeAsync(campusSanFrancisco, campusSanJuanPablo);

        var edificio16 = new Building(
            "Edificio 16",
            3,
            new Coordinate(-38.7336, -72.6021),
            campusSanFrancisco,
            openTime: new TimeOnly(8, 0),
            closeTime: new TimeOnly(21, 0),
            services: "Wifi, Baños, Calefacción"
        );

        var edificio12 = new Building(
            "Edificio 12",
            3,
            new Coordinate(-38.7332, -72.6015),
            campusSanFrancisco,
            openTime: new TimeOnly(8, 0),
            closeTime: new TimeOnly(20, 0),
            services: "Wifi, Baños, Biblioteca"
        );

        var edificio8 = new Building(
            "Edificio 8",
            3,
            new Coordinate(-38.7115, -72.5850),
            campusSanJuanPablo,
            openTime: new TimeOnly(8, 0),
            closeTime: new TimeOnly(21, 0),
            services: "Wifi, Baños, Laboratorios"
        );

        var edificio7 = new Building(
            "Edificio 7",
            3,
            new Coordinate(-38.7120, -72.5860),
            campusSanJuanPablo,
            openTime: new TimeOnly(8, 0),
            closeTime: new TimeOnly(20, 0),
            services: "Wifi, Baños, Cafetería"
        );

        await context.Buildings.AddRangeAsync(edificio16, edificio12, edificio8, edificio7);

        var rooms = new List<Room>();

        void CreateRoomsForBuilding(Building building, string prefix)
        {
            rooms.Add(new Room($"{prefix}-LAB", 1, building, catLaboratorio));

            for (int floor = 1; floor <= building.FloorsCount; floor++)
            {
                rooms.Add(new Room($"{prefix}-{floor}01", floor, building, catSalaClases));
                rooms.Add(new Room($"{prefix}-{floor}02", floor, building, catSalaClases));
            }
        }

        CreateRoomsForBuilding(edificio16, "16");
        CreateRoomsForBuilding(edificio12, "12");
        CreateRoomsForBuilding(edificio8, "8");
        CreateRoomsForBuilding(edificio7, "7");

        await context.Rooms.AddRangeAsync(rooms);

        var structureSF = new StructureEntity(
            "Punto de Estudio San Francisco",
            new Coordinate(-38.7338, -72.6025),
            campusSanFrancisco,
            catEstudio
        );

        var structureSJP = new StructureEntity(
            "Centro de Estudio Juan Pablo II",
            new Coordinate(-38.7119, -72.5852),
            campusSanJuanPablo,
            catEstudio
        );

        await context.Structures.AddRangeAsync(structureSF, structureSJP);

        await context.SaveChangesAsync();
    }
}
