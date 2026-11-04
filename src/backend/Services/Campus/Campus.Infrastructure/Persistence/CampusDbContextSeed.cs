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
        if (await context.Buildings.AnyAsync(b => b.Name == "Ricardo Ferrando")) return;

        if (await context.Campuses.AnyAsync())
        {
            context.Rooms.RemoveRange(context.Rooms);
            context.Structures.RemoveRange(context.Structures);
            context.Buildings.RemoveRange(context.Buildings);
            context.Campuses.RemoveRange(context.Campuses);
            context.Categories.RemoveRange(context.Categories);
            await context.SaveChangesAsync();
        }

        var catAula = new Category("Aula", "school", "Sala destinada a actividades academicas y clases", 1);
        var catSalaPrueba = new Category("Sala de prueba", "meeting_room", "Categoría simulada para desarrollo", 2);
        var catServicioPrueba = new Category("Servicio de prueba", "place", "Categoría simulada para desarrollo", 3);

        await context.Categories.AddRangeAsync(catAula, catSalaPrueba, catServicioPrueba);

        var campusSanJuanPablo = new CampusEntity(
            "Campus San Juan Pablo II",
            "Rudecindo Ortega 02950, Temuco",
            new Coordinate(-38.70258705210351, -72.54796766306328),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        var campusSanFrancisco = new CampusEntity(
            "Campus San Francisco",
            "Manuel Montt 56, Temuco",
            new Coordinate(-38.73723052947173, -72.6015075387534),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        var campusLuisRivas = new CampusEntity(
            "Campus Dr. Luis Rivas del Canto",
            "Rudecindo Ortega 03690, Temuco",
            new Coordinate(-38.698095921143256, -72.54603098119483),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        var campusMenchacaLira = new CampusEntity(
            "Campus Mons. Alejandro Menchaca Lira",
            "Av. Alemania 0422, Temuco",
            new Coordinate(-38.735977541264724, -72.60753510927255),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        var campusContrerasNavia = new CampusEntity(
            "Campus Mons. Sergio Contreras Navia",
            "Av. Alemania 0211, Temuco",
            new Coordinate(-38.735988043073604, -72.60445793831946),
            zoom: 16.00m,
            pitch: 50.00m,
            bearing: -20.00m
        );

        await context.Campuses.AddRangeAsync(
            campusSanJuanPablo,
            campusSanFrancisco,
            campusLuisRivas,
            campusMenchacaLira,
            campusContrerasNavia
        );

        var ricardoFerrando = new Building(
            "Ricardo Ferrando",
            5,
            new Coordinate(-38.703081071947835, -72.54920466606366),
            campusSanJuanPablo,
            catAula
        );

        var faad = new Building(
            "FAAD",
            5,
            new Coordinate(-38.70420284285198, -72.54970950229118),
            campusSanJuanPablo,
            catAula
        );

        var diseno = new Building(
            "Diseño",
            2,
            new Coordinate(-38.70381721809167, -72.54934703011469),
            campusSanJuanPablo,
            catAula
        );

        var agustinaHidalgo = new Building(
            "Agustina Hidalgo",
            3,
            new Coordinate(-38.70387809540409, -72.54874104840168),
            campusSanJuanPablo,
            catAula
        );

        var adalbertoSalas = new Building(
            "Adalberto Salas",
            4,
            new Coordinate(-38.70238907106198, -72.54821132359),
            campusSanJuanPablo,
            catAula
        );

        var waldoMerchant = new Building(
            "WaldoMerchant",
            4,
            new Coordinate(-38.701950859757154, -72.54752910719351),
            campusSanJuanPablo,
            catAula
        );

        var complejoDeportivo = new Building(
            "Complejo Deportivo",
            2,
            new Coordinate(-38.701308741128464, -72.54642730645514),
            campusSanJuanPablo,
            catAula
        );

        var sfPrueba1 = new Building(
            "Edificio de prueba 1",
            2,
            new Coordinate(-38.73713052947173, -72.60140753875339),
            campusSanFrancisco,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var sfPrueba2 = new Building(
            "Edificio de prueba 2",
            2,
            new Coordinate(-38.73703052947173, -72.60130753875339),
            campusSanFrancisco,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var lrPrueba1 = new Building(
            "Edificio de prueba 1",
            2,
            new Coordinate(-38.69799592114325, -72.54593098119483),
            campusLuisRivas,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var lrPrueba2 = new Building(
            "Edificio de prueba 2",
            2,
            new Coordinate(-38.69789592114326, -72.54583098119483),
            campusLuisRivas,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var mlPrueba1 = new Building(
            "Edificio de prueba 1",
            2,
            new Coordinate(-38.73587754126472, -72.60743510927254),
            campusMenchacaLira,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var mlPrueba2 = new Building(
            "Edificio de prueba 2",
            2,
            new Coordinate(-38.735777541264724, -72.60733510927254),
            campusMenchacaLira,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var cnPrueba1 = new Building(
            "Edificio de prueba 1",
            2,
            new Coordinate(-38.7358880430736, -72.60435793831945),
            campusContrerasNavia,
            catSalaPrueba,
            services: "Datos simulados"
        );

        var cnPrueba2 = new Building(
            "Edificio de prueba 2",
            2,
            new Coordinate(-38.735788043073605, -72.60425793831945),
            campusContrerasNavia,
            catSalaPrueba,
            services: "Datos simulados"
        );

        await context.Buildings.AddRangeAsync(
            ricardoFerrando,
            faad,
            diseno,
            agustinaHidalgo,
            adalbertoSalas,
            waldoMerchant,
            complejoDeportivo,
            sfPrueba1,
            sfPrueba2,
            lrPrueba1,
            lrPrueba2,
            mlPrueba1,
            mlPrueba2,
            cnPrueba1,
            cnPrueba2
        );

        var rooms = new List<Room>();

        void AddRooms(Building building, Category category, params (string Name, int Floor)[] definitions)
        {
            foreach (var (name, floor) in definitions)
            {
                rooms.Add(new Room(name, floor, building, category));
            }
        }

        AddRooms(ricardoFerrando, catAula,
            ("CJP07_101", 1), ("CJP07_103", 1), ("CJP07_107", 1), ("CJP07_117", 1),
            ("CJP07_132", 1), ("CJP07_134", 1), ("CJP07_175", 1), ("CJP07_201", 2),
            ("CJP07_203", 2), ("CJP07_215", 2), ("CJP07_217", 2), ("CJP07_232", 2),
            ("CJP07_234", 2), ("CJP07_236", 2), ("CJP07_238", 2), ("CJP07_261", 2),
            ("CJP07_263", 2), ("CJP07_265", 2), ("CJP07_275", 2), ("CJP07_301", 3),
            ("CJP07_317", 3), ("CJP07_325", 3), ("CJP07_332", 3), ("CJP07_334", 3),
            ("CJP07_350", 3), ("CJP07_361", 3), ("CJP07_363", 3), ("CJP07_365", 3),
            ("CJP07_375", 3), ("CJP07_432", 4), ("CJP07_461", 4), ("CJP07_463", 4),
            ("CJP07_465", 4), ("CJP07_475", 4), ("CJP07_590", 5)
        );

        AddRooms(faad, catAula,
            ("CJP01_115", 1), ("CJP01_120", 1), ("CJP01_125", 1), ("CJP01_130", 1),
            ("CJP01_135", 1), ("CJP01_150", 1), ("CJP01_310", 3), ("CJP01_330", 3),
            ("CJP01_350", 3), ("CJP01_410", 4), ("CJP01_420", 4), ("CJP01_430", 4),
            ("CJP01_450", 4), ("CJP01_510", 5), ("CJP01_550", 5)
        );

        AddRooms(diseno, catAula,
            ("CJP02_105", 1), ("CJP02_110", 1), ("CJP02_115", 1), ("CJP02_120", 1),
            ("CJP02_125", 1), ("CJP02_130", 1), ("CJP02_150", 1), ("CJP02_210", 2),
            ("CJP02_212", 2), ("CJP02_214", 2), ("CJP02_216", 2), ("CJP02_218", 2)
        );

        AddRooms(agustinaHidalgo, catAula,
            ("CJP03_103", 1), ("CJP03_105", 1), ("CJP03_107", 1), ("CJP03_109", 1),
            ("CJP03_301", 3), ("CJP03_302", 3), ("CJP03_303", 3), ("CJP03_304", 3)
        );

        AddRooms(adalbertoSalas, catAula,
            ("CJP08_102", 1), ("CJP08_105", 1), ("CJP08_108", 1), ("CJP08_125", 1),
            ("CJP08_135", 1), ("CJP08_136", 1), ("CJP08_139", 1), ("CJP08_146", 1),
            ("CJP08_162", 1), ("CJP08_165", 1), ("CJP08_170", 1), ("CJP08_175", 1),
            ("CJP08_180", 1), ("CJP08_185", 1), ("CJP08_190", 1), ("CJP08_195", 1),
            ("CJP08_260", 2), ("CJP08_262", 2), ("CJP08_268", 2), ("CJP08_270", 2),
            ("CJP08_275", 2), ("CJP08_280", 2), ("CJP08_285", 2), ("CJP08_290", 2),
            ("CJP08_362", 3), ("CJP08_365", 3), ("CJP08_370", 3), ("CJP08_375", 3),
            ("CJP08_380", 3), ("CJP08_385", 3), ("CJP08_390", 3), ("CJP08_462", 4),
            ("CJP08_465", 4), ("CJP08_470", 4), ("CJP08_475", 4), ("CJP08_480", 4),
            ("CJP08_485", 4), ("CJP08_490", 4)
        );

        AddRooms(waldoMerchant, catAula,
            ("CJP10_110", 1), ("CJP10_120", 1), ("CJP10_125", 1), ("CJP10_155", 1),
            ("CJP10_165", 1), ("CJP10_203", 2), ("CJP10_205", 2), ("CJP10_210", 2),
            ("CJP10_225", 2), ("CJP10_230", 2), ("CJP10_305", 3), ("CJP10_307", 3),
            ("CJP10_310", 3), ("CJP10_315", 3), ("CJP10_320", 3), ("CJP10_325", 3),
            ("CJP10_330", 3), ("CJP10_403", 4), ("CJP10_405", 4), ("CJP10_410", 4),
            ("CJP10_415", 4), ("CJP10_420", 4), ("CJP10_425", 4), ("CJP10_430", 4),
            ("CJP10_435", 4)
        );

        AddRooms(complejoDeportivo, catAula,
            ("CJP12_100", 1), ("CJP12_150", 1), ("CJP12_155", 1), ("CJP12_160", 1),
            ("CJP12_165", 1), ("CJP12_180", 1), ("CJP12_190", 1), ("CJP12_205", 2),
            ("CJP12_210", 2), ("CJP12_215", 2), ("CJP12_220", 2), ("CJP12_225", 2),
            ("CJP12_244", 2), ("CJP12_246", 2), ("CJP12_250", 2), ("CJP12_255", 2),
            ("CJP12_260", 2), ("CJP12_265", 2)
        );

        foreach (var testBuilding in new[] { sfPrueba1, sfPrueba2, lrPrueba1, lrPrueba2, mlPrueba1, mlPrueba2, cnPrueba1, cnPrueba2 })
        {
            AddRooms(testBuilding, catSalaPrueba, ("Prueba 101", 1), ("Prueba 102", 2));
        }

        await context.Rooms.AddRangeAsync(rooms);

        var structures = new[]
        {
            new StructureEntity("Punto de encuentro de prueba", new Coordinate(-38.737330529471734, -72.60140753875339), campusSanFrancisco, catServicioPrueba),
            new StructureEntity("Punto de encuentro de prueba", new Coordinate(-38.702687052103514, -72.54786766306327), campusSanJuanPablo, catServicioPrueba),
            new StructureEntity("Punto de encuentro de prueba", new Coordinate(-38.69819592114326, -72.54593098119483), campusLuisRivas, catServicioPrueba),
            new StructureEntity("Punto de encuentro de prueba", new Coordinate(-38.73607754126473, -72.60743510927254), campusMenchacaLira, catServicioPrueba),
            new StructureEntity("Punto de encuentro de prueba", new Coordinate(-38.73608804307361, -72.60435793831945), campusContrerasNavia, catServicioPrueba),
            new StructureEntity("Servicio de prueba", new Coordinate(-38.73743052947173, -72.60130753875339), campusSanFrancisco, catServicioPrueba),
            new StructureEntity("Servicio de prueba", new Coordinate(-38.70278705210351, -72.54776766306327), campusSanJuanPablo, catServicioPrueba),
            new StructureEntity("Servicio de prueba", new Coordinate(-38.698295921143256, -72.54583098119483), campusLuisRivas, catServicioPrueba),
            new StructureEntity("Servicio de prueba", new Coordinate(-38.73617754126472, -72.60733510927254), campusMenchacaLira, catServicioPrueba),
            new StructureEntity("Servicio de prueba", new Coordinate(-38.736188043073604, -72.60425793831945), campusContrerasNavia, catServicioPrueba)
        };

        await context.Structures.AddRangeAsync(structures);

        await context.SaveChangesAsync();
    }
}
