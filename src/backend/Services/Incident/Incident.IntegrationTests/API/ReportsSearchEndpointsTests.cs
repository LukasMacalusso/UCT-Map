using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence.Repositories;
using Incident.IntegrationTests.Fixtures;
using System.Net;
using System.Net.Http.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// End-to-end del buscador de reportes (<c>GET /api/incident/reports</c>),
/// incluyendo filtros, orden y paginación.
/// </summary>
[Collection(MongoCollection.Name)]
public class ReportsSearchEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/incident/reports";

    public ReportsSearchEndpointsTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(Factory.CreateContext());

    private static Ticket NewTicket(
        Guid? userId = null,
        Guid? structureId = null,
        Tickets type = Tickets.Pending,
        bool isActive = true,
        DateTime? reportedAt = null,
        string? lostObjectId = null,
        bool withComplaint = false,
        string? complaintTitle = null,
        string? complaintDescription = null,
        Complainenum complaintStatus = Complainenum.Claim) => new()
        {
            UserRefId = userId ?? Guid.NewGuid(),
            StructureRefId = structureId ?? Guid.NewGuid(),
            TicketType = type,
            IsActive = isActive,
            ReportedAt = reportedAt ?? new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
            LostObjectId = lostObjectId,
            ComplaintDetails = withComplaint || complaintTitle is not null || complaintDescription is not null
                ? new ComplaintDetails
                {
                    Title = complaintTitle ?? "Reclamo",
                    Description = complaintDescription ?? "Descripción del reclamo",
                    Status = complaintStatus
                }
                : null
        };

    private async Task<TicketPageResponse> SearchAsync(string query = "")
    {
        var response = await Http.GetAsync($"{Endpoint}{query}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var page = await ReadJsonAsync<TicketPageResponse>(response);
        Assert.NotNull(page);
        return page!;
    }

    [DockerFact]
    public async Task Get_SinFiltros_RetornaTodosLosTickets()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket());
        await repository.CreateAsync(NewTicket());
        await repository.CreateAsync(NewTicket());

        var page = await SearchAsync();

        Assert.Equal(3, page.TotalCount);
        Assert.Equal(3, page.Items.Count);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorType_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Resolved));
        await repository.CreateAsync(NewTicket(type: Tickets.Resolved));
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));

        var page = await SearchAsync($"?type={(int)Tickets.Resolved}");

        Assert.Equal(2, page.TotalCount);
        Assert.All(page.Items, i => Assert.Equal(Tickets.Resolved, i.TicketType));
    }

    [DockerFact]
    public async Task Get_FiltrandoPorIsActive_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(isActive: false));
        await repository.CreateAsync(NewTicket(isActive: true));

        var page = await SearchAsync("?isActive=false");

        var item = Assert.Single(page.Items);
        Assert.False(item.IsActive);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorStructureRefId_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        var structureId = Guid.NewGuid();
        await repository.CreateAsync(NewTicket(structureId: structureId));
        await repository.CreateAsync(NewTicket(structureId: Guid.NewGuid()));

        var page = await SearchAsync($"?structureRefId={structureId}");

        var item = Assert.Single(page.Items);
        Assert.Equal(structureId, item.StructureRefId);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorUserRefId_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        var userId = Guid.NewGuid();
        await repository.CreateAsync(NewTicket(userId: userId));
        await repository.CreateAsync(NewTicket(userId: Guid.NewGuid()));

        var page = await SearchAsync($"?userRefId={userId}");

        var item = Assert.Single(page.Items);
        Assert.Equal(userId, item.UserRefId);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorLostObjectId_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        var lostObjectId = MongoDB.Bson.ObjectId.GenerateNewId().ToString();
        await repository.CreateAsync(NewTicket(lostObjectId: lostObjectId));
        await repository.CreateAsync(NewTicket());

        var page = await SearchAsync($"?lostObjectId={lostObjectId}");

        var item = Assert.Single(page.Items);
        Assert.Equal(lostObjectId, item.LostObjectId);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorTituloDelReclamo_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(complaintTitle: "Fuga de agua"));
        await repository.CreateAsync(NewTicket(complaintTitle: "Ruido excesivo"));

        var page = await SearchAsync("?complaintDetails.title=fuga");

        var item = Assert.Single(page.Items);
        Assert.Equal("Fuga de agua", item.ComplaintDetails!.Title);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorDescripcionDelReclamo_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Fuga",
            complaintDescription: "Baño del segundo piso"));
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Ruido",
            complaintDescription: "Pasillo del primer piso"));

        var page = await SearchAsync("?complaintDetails.description=segundo");

        var item = Assert.Single(page.Items);
        Assert.Equal("Baño del segundo piso", item.ComplaintDetails!.Description);
    }

    [DockerFact]
    public async Task Get_FiltrandoPorStatusDelReclamo_RetornaSoloLosCoincidentes()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(withComplaint: true, complaintStatus: Complainenum.Match));
        await repository.CreateAsync(NewTicket(withComplaint: true, complaintStatus: Complainenum.Claim));

        var page = await SearchAsync($"?complaintDetails.status={(int)Complainenum.Match}");

        var item = Assert.Single(page.Items);
        Assert.Equal(Complainenum.Match, item.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task Get_CombinandoFiltros_RetornaSoloLosQueCumplenTodos()
    {
        var repository = CreateRepository();
        var structureId = Guid.NewGuid();
        await repository.CreateAsync(NewTicket(
            structureId: structureId, type: Tickets.Resolved, isActive: true));
        await repository.CreateAsync(NewTicket(
            structureId: structureId, type: Tickets.Pending, isActive: true));
        await repository.CreateAsync(NewTicket(
            structureId: structureId, type: Tickets.Resolved, isActive: false));

        var page = await SearchAsync(
            $"?structureRefId={structureId}&type={(int)Tickets.Resolved}&isActive=true");

        var item = Assert.Single(page.Items);
        Assert.Equal(structureId, item.StructureRefId);
        Assert.Equal(Tickets.Resolved, item.TicketType);
        Assert.True(item.IsActive);
    }

    [DockerFact]
    public async Task Get_CuandoElTypeEsInvalido_Retorna400()
    {
        var response = await Http.GetAsync($"{Endpoint}?type=99");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<Microsoft.AspNetCore.Mvc.ProblemDetails>(response);
        Assert.Equal("Invalid type '99'.", problem!.Title);
    }

    [DockerFact]
    public async Task Get_CuandoElComplaintStatusEsInvalido_Retorna400()
    {
        var response = await Http.GetAsync($"{Endpoint}?complaintDetails.status=99");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await ReadJsonAsync<Microsoft.AspNetCore.Mvc.ProblemDetails>(response);
        Assert.Equal("Invalid complaint status '99'.", problem!.Title);
    }

    [DockerFact]
    public async Task Get_CuandoPageSizeSuperaElTope_LoLimitaA10()
    {
        var repository = CreateRepository();
        for (var i = 0; i < 12; i++)
            await repository.CreateAsync(NewTicket());

        var page = await SearchAsync("?page=1&pageSize=50");

        Assert.Equal(12, page.TotalCount);
        Assert.Equal(10, page.Items.Count);
        Assert.Equal(10, page.PageSize);
        Assert.Equal(2, page.TotalPages);
    }

    [DockerFact]
    public async Task Get_CuandoPageEsCero_UsaLaPrimeraPagina()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket());

        var page = await SearchAsync("?page=0");

        Assert.Equal(1, page.Page);
    }

    [DockerFact]
    public async Task Get_OrdenaPorStatusAscendente()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Resolved));
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));
        await repository.CreateAsync(NewTicket(type: Tickets.In_Process));

        var page = await SearchAsync("?sortBy=Status&descending=false");

        Assert.Equal(
            new[] { Tickets.In_Process, Tickets.Pending, Tickets.Resolved },
            page.Items.Select(i => i.TicketType));
    }

    [DockerFact]
    public async Task Get_OrdenaPorReportedAtDescendente()
    {
        var repository = CreateRepository();
        var baseDate = new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc);
        await repository.CreateAsync(NewTicket(reportedAt: baseDate));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(2)));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(1)));

        var page = await SearchAsync("?sortBy=ReportedAt&descending=true");

        Assert.Equal(
            new[] { baseDate.AddDays(2), baseDate.AddDays(1), baseDate },
            page.Items.Select(i => i.ReportedAt));
    }

    [DockerFact]
    public async Task Get_EscapaLosCaracteresRegexDelReclamo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(complaintTitle: "Mochila (negra)"));
        await repository.CreateAsync(NewTicket(complaintTitle: "Mochila negra"));

        var query = $"?complaintDetails.title={Uri.EscapeDataString("(negra)")}";
        var page = await SearchAsync(query);

        var item = Assert.Single(page.Items);
        Assert.Equal("Mochila (negra)", item.ComplaintDetails!.Title);
    }

    [DockerFact]
    public async Task Get_SinCoincidencias_RetornaPaginaVacia()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));

        var page = await SearchAsync($"?type={(int)Tickets.Dismissed}");

        Assert.Equal(0, page.TotalCount);
        Assert.Empty(page.Items);
    }
}
