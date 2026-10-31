using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence.Repositories;
using Incident.IntegrationTests.Fixtures;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// End-to-end del DELETE de objetos perdidos: solo Admin y ObjectsOfficer.
/// </summary>
[Collection(MongoCollection.Name)]
public class LostObjectsDeleteEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/lost-objects";

    public LostObjectsDeleteEndpointsTests(MongoFixture fixture) : base(fixture) { }

    private ObjectRepository CreateRepository() => new(Factory.CreateContext());

    private static LostObject NewLostObject() => new()
    {
        Title = "Mochila negra",
        Description = "Dejada en la biblioteca",
        Status = Objectenum.Pending,
        ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
        PhotoUrl = "https://campus.uct.cl/mochila.png",
        StructureRefId = Guid.NewGuid()
    };

    private async Task<string> SeedLostObjectAsync()
    {
        var lostObject = NewLostObject();
        await CreateRepository().CreateAsync(lostObject);
        return lostObject.Id!;
    }

    private void SetToken(Guid userId, string? role = null) =>
        Http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", TestJwtWithRole.Create(userId, role));

    [DockerTheory]
    [InlineData("Admin")]
    [InlineData("ObjectsOfficer")]
    public async Task Delete_ConRolAutorizado_Retorna200YBorraElObjeto(string role)
    {
        var id = await SeedLostObjectAsync();
        SetToken(Guid.NewGuid(), role);

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(await CreateRepository().GetByIdAsync(id));
    }

    [DockerTheory]
    [InlineData("ComplaintsOfficer")]
    [InlineData("Student")]
    public async Task Delete_ConRolNoAutorizado_Retorna400YNoBorra(string role)
    {
        var id = await SeedLostObjectAsync();
        SetToken(Guid.NewGuid(), role);

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.NotNull(await CreateRepository().GetByIdAsync(id));
    }

    [DockerFact]
    public async Task Delete_CuandoElTokenNoTieneRol_Retorna400YNoBorra()
    {
        var id = await SeedLostObjectAsync();
        SetToken(Guid.NewGuid());

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.NotNull(await CreateRepository().GetByIdAsync(id));
    }

    [DockerFact]
    public async Task Delete_CuandoElObjetoNoExiste_Retorna404()
    {
        SetToken(Guid.NewGuid(), "Admin");

        var response = await Http.DeleteAsync($"{Endpoint}/64b000000000000000000000");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Contains("was not found", problem!.Title);
    }
}
