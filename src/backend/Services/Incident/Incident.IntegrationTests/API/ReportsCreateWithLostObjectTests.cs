using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence.Repositories;
using Incident.IntegrationTests.Fixtures;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// End-to-end de la creación de reportes con referencia a un objeto perdido,
/// con reclamo embebido y con un tipo de ticket inválido.
/// </summary>
[Collection(MongoCollection.Name)]
public class ReportsCreateWithLostObjectTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/reports";

    private static readonly Guid TestUserId = Guid.NewGuid();

    public ReportsCreateWithLostObjectTests(MongoFixture fixture) : base(fixture) { }

    protected override void ConfigureHttp(HttpClient http) =>
        http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", TestJwtWithRole.Create(TestUserId, "ComplaintsOfficer"));

    private ObjectRepository CreateObjectRepository() => new(Factory.CreateContext());

    private sealed record CreatedResponse(string Id);

    private static object Body(
        int ticketType = (int)Tickets.Pending,
        string? lostObjectId = null,
        object? complaint = null) => new
        {
            userRefId = Guid.NewGuid(),
            structureRefId = Guid.NewGuid(),
            ticketType,
            isActive = true,
            reportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
            lostObjectId,
            complaint
        };

    private async Task<string> SeedLostObjectAsync()
    {
        var lostObject = new LostObject
        {
            Title = "Mochila negra",
            Description = "Dejada en la biblioteca",
            Status = Objectenum.Pending,
            ReportedAt = DateTime.UtcNow,
            PhotoUrl = "https://campus.uct.cl/mochila.png",
            StructureRefId = Guid.NewGuid()
        };
        await CreateObjectRepository().CreateAsync(lostObject);
        return lostObject.Id!;
    }

    [DockerFact]
    public async Task Post_ConLostObjectIdExistente_Retorna201YElGetLoExpone()
    {
        var lostObjectId = await SeedLostObjectAsync();

        var response = await Http.PostAsync(Endpoint, JsonBody(Body(lostObjectId: lostObjectId)));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<CreatedResponse>(response);

        var get = await Http.GetAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
        var ticket = await ReadJsonAsync<TicketResponse>(get);
        Assert.Equal(lostObjectId, ticket!.LostObjectId);
        Assert.Equal(TestUserId, ticket.UserRefId);
    }

    [DockerFact]
    public async Task Post_ConLostObjectIdInexistente_Retorna400ConElDetalle()
    {
        var lostObjectId = MongoDB.Bson.ObjectId.GenerateNewId().ToString();

        var response = await Http.PostAsync(Endpoint, JsonBody(Body(lostObjectId: lostObjectId)));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Contains("not found", problem!.Title);
    }

    [DockerFact]
    public async Task Post_ConTicketTypeInvalido_Retorna400()
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(Body(ticketType: 99)));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<ProblemDetails>(response);
        Assert.Equal("Invalid status '99'", problem!.Title);
    }

    [DockerFact]
    public async Task Post_ConReclamo_Retorna201YElGetDevuelveElDetalle()
    {
        var response = await Http.PostAsync(Endpoint, JsonBody(Body(complaint: new
        {
            title = "Fuga de agua",
            description = "Baño del segundo piso",
            status = (int)Complainenum.Claim
        })));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<CreatedResponse>(response);

        var get = await Http.GetAsync($"{Endpoint}/{created!.Id}");
        var ticket = await ReadJsonAsync<TicketResponse>(get);

        Assert.NotNull(ticket!.ComplaintDetails);
        Assert.Equal("Fuga de agua", ticket.ComplaintDetails.Title);
        Assert.Equal("Baño del segundo piso", ticket.ComplaintDetails.Description);
        Assert.Equal(Complainenum.Claim, ticket.ComplaintDetails.Status);
    }
}
