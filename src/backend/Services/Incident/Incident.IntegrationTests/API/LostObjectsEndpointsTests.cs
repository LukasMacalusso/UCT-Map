using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

[Collection(MongoCollection.Name)]
public class LostObjectsEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/lost-objects";

    public LostObjectsEndpointsTests(MongoFixture fixture) : base(fixture) { }

    private ObjectRepository CreateRepository() => new(Factory.CreateContext());

    private static object NewLostObjectBody(
        Guid? structureId = null,
        string photoUrl = "https://campus.uct.cl/mochila.png",
        int status = 0) => new
        {
            title = "Mochila negra",
            description = "Dejada en la biblioteca",
            status,
            photoUrl,
            structureId = structureId ?? Guid.NewGuid()
        };

    private async Task<string> CreateLostObjectAsync(
        Guid? structureId = null,
        string photoUrl = "https://campus.uct.cl/mochila.png")
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(NewLostObjectBody(structureId, photoUrl)));
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<CreatedResponse>(response);
        return created!.Id;
    }

    private sealed record CreatedResponse(string Id);

    [DockerFact]
    public async Task Post_CuandoElRequestEsValido_Retorna201ConElId()
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(NewLostObjectBody()));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.NotNull(response.Headers.Location);
        Assert.Contains(Endpoint + "/", response.Headers.Location!.ToString());

        var created = await ReadJsonAsync<CreatedResponse>(response);
        Assert.False(string.IsNullOrEmpty(created!.Id));

        var persisted = await CreateRepository().GetByIdAsync(created.Id);
        Assert.NotNull(persisted);
        Assert.Equal("Mochila negra", persisted!.Title);
        Assert.Equal(Objectenum.Pending, persisted.Status);
    }

    [DockerFact]
    public async Task Post_CuandoLaPhotoUrlNoEsValida_Retorna400()
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(NewLostObjectBody(photoUrl: "no-es-una-url")));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Equal("Invalid Photo URL format.", problem!.Title);
    }

    [DockerFact]
    public async Task Post_CuandoElStructureIdEsVacio_Retorna400()
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(NewLostObjectBody(structureId: Guid.Empty)));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Equal("Structure ID is required.", problem!.Title);
    }

    [DockerFact]
    public async Task GetById_CuandoNoExiste_Retorna404()
    {
        var response = await Http.GetAsync($"{Endpoint}/64b000000000000000000000");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [DockerFact]
    public async Task GetById_CuandoExiste_Retorna204SinContenido()
    {
        // Comportamiento actual: el handler carga los datos pero el controller
        // responde 204 y descarta el body.
        var id = await CreateLostObjectAsync();

        var response = await Http.GetAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Empty(await response.Content.ReadAsStringAsync());
    }

    // ---------- GET (search) ----------

    private static LostObject NewLostObject(
        string title = "Mochila negra",
        int status = 0,
        Guid? structureId = null) => new()
        {
            Title = title,
            Description = "Dejada en la biblioteca",
            Status = (Objectenum)status,
            ReportedAt = DateTime.UtcNow,
            PhotoUrl = "https://campus.uct.cl/mochila.png",
            StructureRefId = structureId ?? Guid.NewGuid()
        };

    [DockerFact]
    public async Task Get_SinFiltros_Retorna200ConTodos()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Mochila"));
        await repository.CreateAsync(NewLostObject("Paraguas"));

        var response = await Http.GetAsync(Endpoint);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await ReadJsonAsync<LostObjectPageResponse>(response);
        Assert.NotNull(page);
        Assert.Equal(2, page!.TotalCount);
        Assert.Equal(2, page.Items.Count);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorStatus_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Resuelto 1", (int)Objectenum.Resolved));
        await repository.CreateAsync(NewLostObject("Resuelto 2", (int)Objectenum.Resolved));
        await repository.CreateAsync(NewLostObject("Pendiente", (int)Objectenum.Pending));

        var response = await Http.GetAsync($"{Endpoint}?status={(int)Objectenum.Resolved}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await ReadJsonAsync<LostObjectPageResponse>(response);
        Assert.Equal(2, page!.TotalCount);
        Assert.All(page.Items, i => Assert.Equal(nameof(Objectenum.Resolved), i.Status));
    }

    [DockerFact]
    public async Task Get_FiltrandoPorTitle_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewLostObject("Mochila Negra"));
        await repository.CreateAsync(NewLostObject("Paraguas azul"));

        var response = await Http.GetAsync($"{Endpoint}?title=mochila");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await ReadJsonAsync<LostObjectPageResponse>(response);
        var item = Assert.Single(page!.Items);
        Assert.Equal("Mochila Negra", item.Title);
    }

    [DockerFact]
    public async Task Get_CuandoElStatusEsInvalido_Retorna400()
    {
        var response = await Http.GetAsync($"{Endpoint}?status=99");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Equal("Invalid status '99'.", problem!.Title);
    }

    [DockerFact]
    public async Task Get_CuandoPageSizeSuperaElTope_LoLimitaA10()
    {
        var repository = CreateRepository();
        for (var i = 0; i < 12; i++)
            await repository.CreateAsync(NewLostObject($"Objeto {i:D2}"));

        var response = await Http.GetAsync($"{Endpoint}?page=1&pageSize=50");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await ReadJsonAsync<LostObjectPageResponse>(response);
        Assert.Equal(12, page!.TotalCount);
        Assert.Equal(10, page.Items.Count);
        Assert.Equal(10, page.PageSize);
    }

    [DockerFact]
    public async Task PatchStatus_CuandoElObjetoExiste_Retorna204YSePersisteElCambio()
    {
        var id = await CreateLostObjectAsync();

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/lost/status",
            JsonBody(new { status = (int)Objectenum.Canceled }));

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var persisted = await CreateRepository().GetByIdAsync(id);
        Assert.Equal(Objectenum.Canceled, persisted!.Status);
    }

    [DockerFact]
    public async Task PatchStatus_CuandoElObjetoNoExiste_Retorna404()
    {
        var response = await Http.PatchAsync(
            $"{Endpoint}/64b000000000000000000000/lost/status",
            JsonBody(new { status = (int)Objectenum.Resolved }));

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [DockerFact]
    public async Task PatchStatus_CuandoElStatusEsInvalido_Retorna400()
    {
        var id = await CreateLostObjectAsync();

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/lost/status",
            JsonBody(new { status = 42 }));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
