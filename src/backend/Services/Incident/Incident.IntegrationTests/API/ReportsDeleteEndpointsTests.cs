using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence.Repositories;
using Incident.IntegrationTests.Fixtures;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// End-to-end del DELETE de reportes: el dueño puede borrar siempre y los
/// demás usuarios necesitan rol Admin, ObjectsOfficer o ComplaintsOfficer.
/// </summary>
[Collection(MongoCollection.Name)]
public class ReportsDeleteEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/reports";

    public ReportsDeleteEndpointsTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(Factory.CreateContext());

    private static Ticket NewTicket(Guid owner) => new()
    {
        UserRefId = owner,
        StructureRefId = Guid.NewGuid(),
        TicketType = Tickets.Pending,
        IsActive = true,
        ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc)
    };

    private async Task<(string Id, Guid Owner)> SeedTicketAsync()
    {
        var owner = Guid.NewGuid();
        var ticket = NewTicket(owner);
        await CreateRepository().CreateAsync(ticket);
        return (ticket.Id!, owner);
    }

    private void SetToken(Guid userId, string? role = null) =>
        Http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", TestJwtWithRole.Create(userId, role));

    [DockerFact]
    public async Task Delete_CuandoEsElDuenio_Retorna200YBorraElTicket()
    {
        var (id, owner) = await SeedTicketAsync();
        // El dueño puede borrar incluso sin un rol autorizado.
        SetToken(owner, "Student");

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(await CreateRepository().GetByIdAsync(id));
    }

    [DockerTheory]
    [InlineData("Admin")]
    [InlineData("ObjectsOfficer")]
    [InlineData("ComplaintsOfficer")]
    public async Task Delete_CuandoNoEsElDuenioPeroTieneRolAutorizado_Retorna200YBorra(string role)
    {
        var (id, _) = await SeedTicketAsync();
        SetToken(Guid.NewGuid(), role);

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(await CreateRepository().GetByIdAsync(id));
    }

    [DockerFact]
    public async Task Delete_CuandoNoEsElDuenioYNoTieneRolAutorizado_Retorna400YNoBorra()
    {
        var (id, _) = await SeedTicketAsync();
        SetToken(Guid.NewGuid(), "Student");

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.NotNull(await CreateRepository().GetByIdAsync(id));
    }

    [DockerFact]
    public async Task Delete_CuandoElTokenNoTieneRol_Retorna400YNoBorra()
    {
        var (id, _) = await SeedTicketAsync();
        SetToken(Guid.NewGuid());

        var response = await Http.DeleteAsync($"{Endpoint}/{id}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.NotNull(await CreateRepository().GetByIdAsync(id));
    }

    [DockerFact]
    public async Task Delete_CuandoElTicketNoExiste_Retorna404()
    {
        SetToken(Guid.NewGuid(), "Admin");

        var response = await Http.DeleteAsync($"{Endpoint}/64b000000000000000000000");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Contains("was not found", problem!.Title);
    }
}
