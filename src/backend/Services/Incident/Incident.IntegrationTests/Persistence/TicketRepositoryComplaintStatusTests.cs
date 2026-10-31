using Incident.Domain.Entities;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;

namespace Incident.IntegrationTests.Persistence;

/// <summary>
/// Cubre la actualización del estado del reclamo embebido y casos de
/// actualización sobre tickets inexistentes.
/// </summary>
[Collection(MongoCollection.Name)]
public class TicketRepositoryComplaintStatusTests : MongoTestBase
{
    public TicketRepositoryComplaintStatusTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(CreateContext());

    private static Ticket NewTicket(bool withComplaint = true) => new()
    {
        UserRefId = Guid.NewGuid(),
        StructureRefId = Guid.NewGuid(),
        TicketType = Tickets.Pending,
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

    [DockerFact]
    public async Task UpdateStatusComplainAsync_CuandoElEstadoCambia_RetornaTrueYSePersiste()
    {
        var repository = CreateRepository();
        var ticket = NewTicket();
        await repository.CreateAsync(ticket);

        var updated = await repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Match);

        Assert.True(updated);
        var persisted = await repository.GetByIdAsync(ticket.Id!);
        Assert.Equal(Complainenum.Match, persisted!.ComplaintDetails!.Status);
    }

    [DockerFact]
    public async Task UpdateStatusComplainAsync_CuandoElEstadoNoCambia_RetornaFalse()
    {
        var repository = CreateRepository();
        var ticket = NewTicket();
        await repository.CreateAsync(ticket);

        var updated = await repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Claim);

        Assert.False(updated);
    }

    [DockerFact]
    public async Task UpdateStatusComplainAsync_CuandoElTicketNoExiste_RetornaFalse()
    {
        var repository = CreateRepository();

        var updated = await repository.UpdateStatusComplainAsync(NewTicket(), (int)Complainenum.Match);

        Assert.False(updated);
    }

    [DockerFact]
    public async Task UpdateStatusAsync_CuandoElTicketNoExiste_RetornaFalse()
    {
        var repository = CreateRepository();

        var updated = await repository.UpdateStatusAsync(NewTicket(), (int)Tickets.Resolved);

        Assert.False(updated);
    }

    [DockerFact]
    public async Task UpdateStatusComplainAsync_CuandoElTicketNoTieneReclamo_LanzaMongoWriteException()
    {
        // Comportamiento actual: Mongo no puede crear "complaint_details.status"
        // cuando complaint_details es null.
        var repository = CreateRepository();
        var ticket = NewTicket(withComplaint: false);
        await repository.CreateAsync(ticket);

        await Assert.ThrowsAsync<MongoDB.Driver.MongoWriteException>(() =>
            repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Match));
    }
}
