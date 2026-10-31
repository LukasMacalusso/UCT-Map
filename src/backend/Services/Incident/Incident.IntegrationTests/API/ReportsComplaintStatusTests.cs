using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence.Repositories;
using Incident.IntegrationTests.Fixtures;
using System.Net;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// End-to-end del PATCH de estado cuando además se actualiza el estado del
/// reclamo embebido (<c>complainStatus</c>).
/// </summary>
[Collection(MongoCollection.Name)]
public class ReportsComplaintStatusTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/reports";

    public ReportsComplaintStatusTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(Factory.CreateContext());

    private static Ticket NewTicket(bool withComplaint, Tickets type = Tickets.Pending) => new()
    {
        UserRefId = Guid.NewGuid(),
        StructureRefId = Guid.NewGuid(),
        TicketType = type,
        IsActive = true,
        ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
        ComplaintDetails = withComplaint
            ? new ComplaintDetails
            {
                Title = "Fuga de agua",
                Description = "Baño del segundo piso",
                Status = Complainenum.Claim
            }
            : null
    };

    private async Task<string> SeedTicketAsync(bool withComplaint, Tickets type = Tickets.Pending)
    {
        var ticket = NewTicket(withComplaint, type);
        await CreateRepository().CreateAsync(ticket);
        return ticket.Id!;
    }

    private async Task<TicketResponse> GetAsync(string id)
    {
        var response = await Http.GetAsync($"{Endpoint}/{id}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var ticket = await ReadJsonAsync<TicketResponse>(response);
        Assert.NotNull(ticket);
        return ticket!;
    }

    [DockerFact]
    public async Task Patch_ConComplainStatusValido_ActualizaTicketYReclamo()
    {
        var id = await SeedTicketAsync(withComplaint: true);

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/report/status",
            JsonBody(new
            {
                status = (int)Tickets.Resolved,
                complainStatus = (int)Complainenum.Match
            }));

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var ticket = await GetAsync(id);
        Assert.Equal(Tickets.Resolved, ticket.TicketType);
        Assert.Equal(Complainenum.Match, ticket.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task Patch_CuandoElTicketNoCambiaPeroElReclamoSi_Retorna204()
    {
        var id = await SeedTicketAsync(withComplaint: true);

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/report/status",
            JsonBody(new
            {
                status = (int)Tickets.Pending,
                complainStatus = (int)Complainenum.Found
            }));

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var ticket = await GetAsync(id);
        Assert.Equal(Complainenum.Found, ticket.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task Patch_CuandoNadaCambia_Retorna400()
    {
        var id = await SeedTicketAsync(withComplaint: true);

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/report/status",
            JsonBody(new { status = (int)Tickets.Pending }));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [DockerFact]
    public async Task Patch_ConComplainStatusInvalido_PeroTicketActualizado_Retorna204()
    {
        // Comportamiento actual: el error del reclamo se ignora si el ticket se actualizó.
        var id = await SeedTicketAsync(withComplaint: true);

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/report/status",
            JsonBody(new { status = (int)Tickets.Resolved, complainStatus = 99 }));

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var ticket = await GetAsync(id);
        Assert.Equal(Tickets.Resolved, ticket.TicketType);
        Assert.Equal(Complainenum.Claim, ticket.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task Patch_ConComplainStatusPeroSinReclamo_ActualizaSoloElTicket()
    {
        var id = await SeedTicketAsync(withComplaint: false);

        var response = await Http.PatchAsync(
            $"{Endpoint}/{id}/report/status",
            JsonBody(new
            {
                status = (int)Tickets.Resolved,
                complainStatus = (int)Complainenum.Match
            }));

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        var ticket = await GetAsync(id);
        Assert.Equal(Tickets.Resolved, ticket.TicketType);
        Assert.Null(ticket.ComplaintDetails);
    }
}
