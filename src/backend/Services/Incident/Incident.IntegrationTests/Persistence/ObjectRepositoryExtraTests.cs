using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;

namespace Incident.IntegrationTests.Persistence;

/// <summary>
/// Completa la cobertura del repositorio de objetos perdidos: borrado
/// exitoso, orden por estado/título y combinación de filtros.
/// </summary>
[Collection(MongoCollection.Name)]
public class ObjectRepositoryExtraTests : MongoTestBase
{
    public ObjectRepositoryExtraTests(MongoFixture fixture) : base(fixture) { }

    private ObjectRepository CreateRepository() => new(CreateContext());

    private static LostObject NewLostObject(
        string title = "Mochila negra",
        Objectenum status = Objectenum.Pending,
        DateTime? reportedAt = null,
        Guid? structureId = null) => new()
        {
            Title = title,
            Description = "Dejada en la biblioteca",
            Status = status,
            ReportedAt = reportedAt ?? new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
            PhotoUrl = "https://campus.uct.cl/mochila.png",
            StructureRefId = structureId ?? Guid.NewGuid()
        };

    private static LostObjectSearchCriteria Criteria(
        string? title = null,
        Guid? structureId = null,
        Objectenum? status = null,
        LostObjectSortField sortBy = LostObjectSortField.ReportedAt,
        bool descending = true,
        int page = 1,
        int pageSize = 10) =>
        new(title, structureId, status, sortBy, descending, page, pageSize);

    [DockerFact]
    public async Task DeleteAsync_CuandoElDocumentoExiste_RetornaTrueYSeElimina()
    {
        var repository = CreateRepository();
        var lostObject = NewLostObject();
        await repository.CreateAsync(lostObject);

        var deleted = await repository.DeleteAsync(lostObject.Id!);

        Assert.True(deleted);
        Assert.Null(await repository.GetByIdAsync(lostObject.Id!));
    }

    [DockerFact]
    public async Task SearchAsync_OrdenaPorStatusAscYDesc()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Resuelto", Objectenum.Resolved));
        await repository.CreateAsync(NewLostObject("Pendiente", Objectenum.Pending));
        await repository.CreateAsync(NewLostObject("Cancelado", Objectenum.Canceled));

        var asc = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.Status, descending: false), CancellationToken.None);
        Assert.Equal(
            new[] { Objectenum.Canceled, Objectenum.Pending, Objectenum.Resolved },
            asc.Items.Select(i => i.Status));

        var desc = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.Status, descending: true), CancellationToken.None);
        Assert.Equal(
            new[] { Objectenum.Resolved, Objectenum.Pending, Objectenum.Canceled },
            desc.Items.Select(i => i.Status));
    }

    [DockerFact]
    public async Task SearchAsync_OrdenaPorTituloAscendente()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Zeta"));
        await repository.CreateAsync(NewLostObject("Alfa"));
        await repository.CreateAsync(NewLostObject("Mango"));

        var result = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.Title, descending: false), CancellationToken.None);

        Assert.Equal(new[] { "Alfa", "Mango", "Zeta" }, result.Items.Select(i => i.Title));
    }

    [DockerFact]
    public async Task SearchAsync_CombinaTituloStatusYStructureId()
    {
        var repository = CreateRepository();
        var structureId = Guid.NewGuid();
        await repository.CreateAsync(NewLostObject("Mochila negra", Objectenum.Resolved, structureId: structureId));
        await repository.CreateAsync(NewLostObject("Mochila azul", Objectenum.Resolved, structureId: structureId));
        await repository.CreateAsync(NewLostObject("Mochila verde", Objectenum.Pending, structureId: structureId));
        await repository.CreateAsync(NewLostObject("Mochila gris", Objectenum.Resolved, structureId: Guid.NewGuid()));

        var result = await repository.SearchAsync(
            Criteria(title: "negra", structureId: structureId, status: Objectenum.Resolved),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Mochila negra", item.Title);
    }

    [DockerFact]
    public async Task SearchAsync_SinCoincidencias_DevuelveVacio()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Mochila negra"));

        var result = await repository.SearchAsync(
            Criteria(title: "no-existe"), CancellationToken.None);

        Assert.Equal(0, result.TotalCount);
        Assert.Empty(result.Items);
    }
}
