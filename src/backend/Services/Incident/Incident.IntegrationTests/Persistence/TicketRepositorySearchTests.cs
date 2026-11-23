using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;

namespace Incident.IntegrationTests.Persistence;

/// <summary>
/// Cubre todos los filtros y el orden del buscador de tickets
/// (<see cref="TicketRepository.SearchAsync"/> y <c>TicketFilters</c>).
/// </summary>
[Collection(MongoCollection.Name)]
public class TicketRepositorySearchTests : MongoTestBase
{
    public TicketRepositorySearchTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(CreateContext());

    private static Ticket NewTicket(
        Guid? userId = null,
        Guid? structureId = null,
        Tickets type = Tickets.Pending,
        bool isActive = true,
        DateTime? reportedAt = null,
        string? lostObjectId = null,
        GeoPoint? location = null,
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
            Location = location,
            ComplaintDetails = withComplaint || complaintTitle is not null || complaintDescription is not null
                ? new ComplaintDetails
                {
                    Title = complaintTitle ?? "Reclamo",
                    Description = complaintDescription ?? "Descripción del reclamo",
                    Status = complaintStatus
                }
                : null
        };

    private static TicketSearchCriteria Criteria(
        Guid? userId = null,
        Guid? structureId = null,
        Tickets? type = null,
        bool? isActive = null,
        TicketSortBy sortBy = TicketSortBy.ReportedAt,
        GeoPoint? location = null,
        string? lostObjectId = null,
        ComplaintSearchCriteria? complaint = null,
        bool descending = true,
        int page = 1,
        int pageSize = 10) =>
        new(userId, structureId, type, isActive, sortBy, location, lostObjectId,
            complaint, descending, page, pageSize);

    [DockerFact]
    public async Task SearchAsync_SinFiltros_DevuelveTodo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket());
        await repository.CreateAsync(NewTicket());

        var result = await repository.SearchAsync(Criteria(), CancellationToken.None);

        Assert.Equal(2, result.TotalCount);
        Assert.Equal(2, result.Items.Count);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorUserRefId()
    {
        var repository = CreateRepository();
        var userId = Guid.NewGuid();
        await repository.CreateAsync(NewTicket(userId: userId));
        await repository.CreateAsync(NewTicket(userId: Guid.NewGuid()));

        var result = await repository.SearchAsync(Criteria(userId: userId), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(userId, item.UserRefId);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorStructureRefId()
    {
        var repository = CreateRepository();
        var structureId = Guid.NewGuid();
        await repository.CreateAsync(NewTicket(structureId: structureId));
        await repository.CreateAsync(NewTicket(structureId: Guid.NewGuid()));

        var result = await repository.SearchAsync(Criteria(structureId: structureId), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(structureId, item.StructureRefId);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorType()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Resolved));
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));

        var result = await repository.SearchAsync(Criteria(type: Tickets.Resolved), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(Tickets.Resolved, item.TicketType);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorIsActive()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(isActive: false));
        await repository.CreateAsync(NewTicket(isActive: true));

        var result = await repository.SearchAsync(Criteria(isActive: false), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.False(item.IsActive);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorLostObjectId()
    {
        var repository = CreateRepository();
        var lostObjectId = ObjectId.GenerateNewId().ToString();
        await repository.CreateAsync(NewTicket(lostObjectId: lostObjectId));
        await repository.CreateAsync(NewTicket());

        var result = await repository.SearchAsync(Criteria(lostObjectId: lostObjectId), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(lostObjectId, item.LostObjectId);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorLocation()
    {
        var repository = CreateRepository();
        var location = new GeoPoint(-71.2345, -33.0456);
        await repository.CreateAsync(NewTicket(location: location));
        await repository.CreateAsync(NewTicket(location: new GeoPoint(-70.0000, -30.0000)));

        var result = await repository.SearchAsync(Criteria(location: location), CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(location.Coordinates, item.Location!.Coordinates);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorTituloDelReclamoCaseInsensitiveYParcial()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(complaintTitle: "Fuga de agua"));
        await repository.CreateAsync(NewTicket(complaintTitle: "Ruido excesivo"));

        var result = await repository.SearchAsync(
            Criteria(complaint: new ComplaintSearchCriteria("fuga", null, null)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Fuga de agua", item.ComplaintDetails!.Title);
    }

    [DockerFact]
    public async Task SearchAsync_EscapaLosCaracteresRegexDelTituloDelReclamo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(complaintTitle: "Mochila (negra)"));
        await repository.CreateAsync(NewTicket(complaintTitle: "Mochila negra"));

        var result = await repository.SearchAsync(
            Criteria(complaint: new ComplaintSearchCriteria("(negra)", null, null)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Mochila (negra)", item.ComplaintDetails!.Title);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorDescripcionDelReclamo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Fuga", complaintDescription: "Baño del segundo piso"));
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Ruido", complaintDescription: "Pasillo del primer piso"));

        var result = await repository.SearchAsync(
            Criteria(complaint: new ComplaintSearchCriteria(null, "segundo", null)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Baño del segundo piso", item.ComplaintDetails!.Description);
    }

    [DockerFact]
    public async Task SearchAsync_EscapaLosCaracteresRegexDeLaDescripcionDelReclamo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Fuga", complaintDescription: "Baño (2do piso)"));
        await repository.CreateAsync(NewTicket(
            complaintTitle: "Fuga", complaintDescription: "Baño 2do piso"));

        var result = await repository.SearchAsync(
            Criteria(complaint: new ComplaintSearchCriteria(null, "(2do piso)", null)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Baño (2do piso)", item.ComplaintDetails!.Description);
    }

    [DockerFact]
    public async Task SearchAsync_FiltraPorStatusDelReclamo()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(withComplaint: true, complaintStatus: Complainenum.Match));
        await repository.CreateAsync(NewTicket(withComplaint: true, complaintStatus: Complainenum.Claim));

        var result = await repository.SearchAsync(
            Criteria(complaint: new ComplaintSearchCriteria(null, null, Complainenum.Match)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal(Complainenum.Match, item.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task SearchAsync_CombinaTodosLosFiltros()
    {
        var repository = CreateRepository();
        var userId = Guid.NewGuid();
        var structureId = Guid.NewGuid();
        var lostObjectId = ObjectId.GenerateNewId().ToString();

        await repository.CreateAsync(NewTicket(
            userId: userId,
            structureId: structureId,
            type: Tickets.Resolved,
            isActive: true,
            lostObjectId: lostObjectId,
            complaintTitle: "Fuga de agua",
            complaintStatus: Complainenum.Match));

        await repository.CreateAsync(NewTicket(
            userId: userId,
            structureId: structureId,
            type: Tickets.Resolved,
            isActive: true,
            lostObjectId: lostObjectId,
            complaintTitle: "Otro reclamo",
            complaintStatus: Complainenum.Claim));

        var result = await repository.SearchAsync(
            Criteria(
                userId: userId,
                structureId: structureId,
                type: Tickets.Resolved,
                isActive: true,
                lostObjectId: lostObjectId,
                complaint: new ComplaintSearchCriteria("fuga", "reclamo", Complainenum.Match)),
            CancellationToken.None);

        var item = Assert.Single(result.Items);
        Assert.Equal("Fuga de agua", item.ComplaintDetails!.Title);
    }

    [DockerFact]
    public async Task SearchAsync_OrdenaPorReportedAtAscYDesc()
    {
        var repository = CreateRepository();
        var baseDate = new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc);
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(1)));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(3)));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(2)));

        var asc = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.ReportedAt, descending: false), CancellationToken.None);
        Assert.Equal(
            new[] { baseDate.AddDays(1), baseDate.AddDays(2), baseDate.AddDays(3) },
            asc.Items.Select(i => i.ReportedAt));

        var desc = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.ReportedAt, descending: true), CancellationToken.None);
        Assert.Equal(
            new[] { baseDate.AddDays(3), baseDate.AddDays(2), baseDate.AddDays(1) },
            desc.Items.Select(i => i.ReportedAt));
    }

    [DockerFact]
    public async Task SearchAsync_OrdenaPorStatusAscYDesc()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Resolved));
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));
        await repository.CreateAsync(NewTicket(type: Tickets.In_Process));

        var asc = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.Status, descending: false), CancellationToken.None);
        Assert.Equal(
            new[] { Tickets.In_Process, Tickets.Pending, Tickets.Resolved },
            asc.Items.Select(i => i.TicketType));

        var desc = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.Status, descending: true), CancellationToken.None);
        Assert.Equal(
            new[] { Tickets.Resolved, Tickets.Pending, Tickets.In_Process },
            desc.Items.Select(i => i.TicketType));
    }

    [DockerFact]
    public async Task SearchAsync_PaginaYDevuelveElTotal()
    {
        var repository = CreateRepository();
        var baseDate = new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc);
        await repository.CreateAsync(NewTicket(reportedAt: baseDate));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(1)));
        await repository.CreateAsync(NewTicket(reportedAt: baseDate.AddDays(2)));

        var firstPage = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.ReportedAt, descending: false, page: 1, pageSize: 2),
            CancellationToken.None);

        Assert.Equal(3, firstPage.TotalCount);
        Assert.Equal(2, firstPage.Items.Count);
        Assert.Equal(baseDate, firstPage.Items[0].ReportedAt);
        Assert.Equal(baseDate.AddDays(1), firstPage.Items[1].ReportedAt);

        var secondPage = await repository.SearchAsync(
            Criteria(sortBy: TicketSortBy.ReportedAt, descending: false, page: 2, pageSize: 2),
            CancellationToken.None);

        Assert.Single(secondPage.Items);
        Assert.Equal(baseDate.AddDays(2), secondPage.Items[0].ReportedAt);
    }

    [DockerFact]
    public async Task SearchAsync_SinCoincidencias_DevuelveVacio()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket(type: Tickets.Pending));

        var result = await repository.SearchAsync(Criteria(type: Tickets.Dismissed), CancellationToken.None);

        Assert.Equal(0, result.TotalCount);
        Assert.Empty(result.Items);
    }
}
