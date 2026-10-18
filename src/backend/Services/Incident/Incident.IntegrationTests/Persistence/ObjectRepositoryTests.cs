using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;

namespace Incident.IntegrationTests.Persistence;

[Collection(MongoCollection.Name)]
public class ObjectRepositoryTests : MongoTestBase
{
    public ObjectRepositoryTests(MongoFixture fixture) : base(fixture) { }

    private ObjectRepository CreateRepository() => new(CreateContext());

    private static LostObject NewLostObject(
        Objectenum status = Objectenum.Pending,
        string title = "Mochila negra",
        DateTime? reportedAt = null,
        Guid? structureId = null) => new()
        {
            Title = title,
            Description = "Dejada en la biblioteca",
            Status = status,
            ReportedAt = reportedAt ?? DateTime.UtcNow,
            PhotoUrl = "https://campus.uct.cl/mochila.png",
            StructureRefId = structureId ?? Guid.NewGuid()
        };

    [DockerFact]
    public async Task CreateAsync_LuegoDeInsertar_AsignaElIdYSePuedeLeer()
    {
        var repository = CreateRepository();
        var lostObject = NewLostObject(Objectenum.In_Process);

        await repository.CreateAsync(lostObject);

        Assert.False(string.IsNullOrEmpty(lostObject.Id));

        var persisted = await repository.GetByIdAsync(lostObject.Id!);
        Assert.NotNull(persisted);
        Assert.Equal("Mochila negra", persisted.Title);
        Assert.Equal("Dejada en la biblioteca", persisted.Description);
        Assert.Equal(Objectenum.In_Process, persisted.Status);
        Assert.Equal("https://campus.uct.cl/mochila.png", persisted.PhotoUrl);
        Assert.Equal(lostObject.StructureRefId, persisted.StructureRefId);
    }

    [DockerFact]
    public async Task GetByIdAsync_ConIdNoObjectId_RetornaNull()
    {
        var repository = CreateRepository();

        var result = await repository.GetByIdAsync("id-invalido");

        Assert.Null(result);
    }

    [DockerFact]
    public async Task UpdateStatusAsync_CuandoElEstadoCambia_RetornaTrueYSePersiste()
    {
        var repository = CreateRepository();
        var lostObject = NewLostObject(Objectenum.Pending);
        await repository.CreateAsync(lostObject);

        var updated = await repository.UpdateStatusAsync(lostObject, (int)Objectenum.Canceled);

        Assert.True(updated);
        var persisted = await repository.GetByIdAsync(lostObject.Id!);
        Assert.Equal(Objectenum.Canceled, persisted!.Status);
    }

    [DockerFact]
    public async Task UpdateStatusAsync_CuandoElEstadoNoCambia_RetornaFalse()
    {
        // Comportamiento actual: si el documento de reemplazo es idéntico,
        // ModifiedCount es 0 y el método informa fallo.
        var repository = CreateRepository();
        var lostObject = NewLostObject(Objectenum.Pending);
        await repository.CreateAsync(lostObject);

        var updated = await repository.UpdateStatusAsync(lostObject, (int)Objectenum.Pending);

        Assert.False(updated);
    }

    [DockerFact]
    public async Task DeleteAsync_SiElDocumentoNoExiste_RetornaFalse()
    {
        var repository = CreateRepository();

        var deleted = await repository.DeleteAsync(ObjectId.GenerateNewId().ToString());

        Assert.False(deleted);
    }

    // ---------- SearchAsync ----------

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
    public async Task SearchAsync_FiltraPorStatus()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject(Objectenum.Pending, "Pendiente"));
        await repository.CreateAsync(NewLostObject(Objectenum.Resolved, "Resuelto"));
        await repository.CreateAsync(NewLostObject(Objectenum.Resolved, "Resuelto 2"));

        var result = await repository.SearchAsync(
            Criteria(status: Objectenum.Resolved), CancellationToken.None);

        Assert.Equal(2, result.TotalCount);
        Assert.Equal(2, result.Items.Count);
        Assert.All(result.Items, i => Assert.Equal(Objectenum.Resolved, i.Status));
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorTitleCaseInsensitiveYParcial()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject(title: "Mochila Negra"));
        await repository.CreateAsync(NewLostObject(title: "Paraguas azul"));

        var result = await repository.SearchAsync(
            Criteria(title: "mochila"), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Mochila Negra", item.Title);
    }

    [DockerFact]
    public async Task SearchAsync_EscapaLosCaracteresRegexDelTitle()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject(title: "Mochila (negra)"));
        await repository.CreateAsync(NewLostObject(title: "Mochila negra"));

        var result = await repository.SearchAsync(
            Criteria(title: "(negra)"), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Mochila (negra)", item.Title);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorStructureId()
    {
        var repository = CreateRepository();
        var target = Guid.NewGuid();
        await repository.CreateAsync(NewLostObject(title: "Objetivo", structureId: target));
        await repository.CreateAsync(NewLostObject(title: "Otro", structureId: Guid.NewGuid()));

        var result = await repository.SearchAsync(
            Criteria(structureId: target), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(target, item.StructureRefId);
    }

    [DockerFact]
    public async Task SearchAsync_PaginaYDevuelveElTotal()
    {
        var repository = CreateRepository();
        var baseDate = new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc);
        await repository.CreateAsync(NewLostObject(title: "A", reportedAt: baseDate));
        await repository.CreateAsync(NewLostObject(title: "B", reportedAt: baseDate.AddDays(1)));
        await repository.CreateAsync(NewLostObject(title: "C", reportedAt: baseDate.AddDays(2)));

        var firstPage = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.ReportedAt, descending: false, page: 1, pageSize: 2),
            CancellationToken.None);

        Assert.Equal(3, firstPage.TotalCount);
        Assert.Equal(2, firstPage.Items.Count);
        Assert.Equal("A", firstPage.Items[0].Title);
        Assert.Equal("B", firstPage.Items[1].Title);

        var secondPage = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.ReportedAt, descending: false, page: 2, pageSize: 2),
            CancellationToken.None);

        Assert.Single(secondPage.Items);
        Assert.Equal("C", secondPage.Items[0].Title);
    }

    [DockerFact]
    public async Task SearchAsync_OrdenaPorTituloDescendente()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject(title: "Alfa"));
        await repository.CreateAsync(NewLostObject(title: "Zeta"));
        await repository.CreateAsync(NewLostObject(title: "Mango"));

        var result = await repository.SearchAsync(
            Criteria(sortBy: LostObjectSortField.Title, descending: true), CancellationToken.None);

        Assert.Equal(new[] { "Zeta", "Mango", "Alfa" }, result.Items.Select(i => i.Title));
    }

    [DockerFact]
    public async Task SearchAsync_SinFiltros_DevuelveTodo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject(title: "Uno"));
        await repository.CreateAsync(NewLostObject(title: "Dos"));

        var result = await repository.SearchAsync(Criteria(), CancellationToken.None);

        Assert.Equal(2, result.TotalCount);
        Assert.Equal(2, result.Items.Count);
    }
}
