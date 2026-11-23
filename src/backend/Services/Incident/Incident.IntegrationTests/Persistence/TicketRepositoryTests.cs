using Incident.Domain.Entities;
using Incident.IntegrationTests.Fixtures;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Incident.IntegrationTests.Persistence;

[Collection(MongoCollection.Name)]
public class TicketRepositoryTests : MongoTestBase
{
    public TicketRepositoryTests(MongoFixture fixture) : base(fixture) { }

    private TicketRepository CreateRepository() => new(CreateContext());

    private static Ticket NewTicket(
        Tickets ticketType = Tickets.Pending,
        bool isActive = true,
        string? title = null) => new()
        {
            UserRefId = Guid.NewGuid(),
            StructureRefId = Guid.NewGuid(),
            TicketType = ticketType,
            IsActive = isActive,
            ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
            ComplaintDetails = title is null ? null : new ComplaintDetails
            {
                Title = title,
                Description = "Descripción del reclamo",
                Status = Complainenum.Claim
            },
            Location = new GeoPoint(-71.2345, -33.0456)
        };

    [DockerFact]
    public async Task CreateAsync_LuegoDeInsertar_AsignaElIdYSePuedeLeer()
    {
        var repository = CreateRepository();
        var ticket = NewTicket(Tickets.In_Process, isActive: false, title: "Reclamo mochila");

        await repository.CreateAsync(ticket);

        Assert.False(string.IsNullOrEmpty(ticket.Id));

        var persisted = await repository.GetByIdAsync(ticket.Id!);
        Assert.NotNull(persisted);
        Assert.Equal(ticket.UserRefId, persisted.UserRefId);
        Assert.Equal(ticket.StructureRefId, persisted.StructureRefId);
        Assert.Equal(Tickets.In_Process, persisted.TicketType);
        Assert.False(persisted.IsActive);
        Assert.Equal(ticket.ReportedAt, persisted.ReportedAt);
        Assert.NotNull(persisted.ComplaintDetails);
        Assert.Equal("Reclamo mochila", persisted.ComplaintDetails.Title);
        Assert.Equal(Complainenum.Claim, persisted.ComplaintDetails.Status);
        Assert.NotNull(persisted.Location);
        Assert.Equal(-71.2345, persisted.Location!.Coordinates[0]);
        Assert.Equal(-33.0456, persisted.Location.Coordinates[1]);
    }

    [DockerFact]
    public async Task GetByIdAsync_ConIdNoObjectId_RetornaNull()
    {
        var repository = CreateRepository();

        var result = await repository.GetByIdAsync("esto-no-es-un-objectid");

        Assert.Null(result);
    }

    [DockerFact]
    public async Task GetAllAsync_DevuelveTodosLosTicketsInsertados()
    {
        var repository = CreateRepository();
        await repository.CreateAsync(NewTicket());
        await repository.CreateAsync(NewTicket());

        var all = await repository.GetAllAsync();

        Assert.Equal(2, all.Count());
    }

    [DockerFact]
    public async Task UpdateAsync_SiElIdExiste_ReemplazaElDocumento()
    {
        var repository = CreateRepository();
        var ticket = NewTicket();
        await repository.CreateAsync(ticket);

        // El reemplazo debe llevar el mismo _id: si llega sin Id, Mongo rechaza
        // la escritura porque el campo _id es inmutable.
        var updated = new Ticket
        {
            Id = ticket.Id,
            UserRefId = ticket.UserRefId,
            StructureRefId = ticket.StructureRefId,
            TicketType = Tickets.Resolved,
            IsActive = false,
            ReportedAt = ticket.ReportedAt
        };
        await repository.UpdateAsync(ticket.Id!, updated);

        var persisted = await repository.GetByIdAsync(ticket.Id!);
        Assert.NotNull(persisted);
        Assert.Equal(Tickets.Resolved, persisted.TicketType);
        Assert.False(persisted.IsActive);
    }

    [DockerFact]
    public async Task UpdateAsync_SiElEntityNoLlevaElMismoId_LanzaExcepcion()
    {
        // Comportamiento actual: ReplaceOneAsync recibe el documento completo y,
        // sin el mismo _id, Mongo rechaza la escritura (campo inmutable).
        var repository = CreateRepository();
        var ticket = NewTicket();
        await repository.CreateAsync(ticket);

        var sinId = new Ticket
        {
            UserRefId = ticket.UserRefId,
            StructureRefId = ticket.StructureRefId,
            TicketType = Tickets.Resolved,
            IsActive = false,
            ReportedAt = ticket.ReportedAt
        };

        await Assert.ThrowsAsync<MongoWriteException>(() =>
            repository.UpdateAsync(ticket.Id!, sinId));
    }

    [DockerFact]
    public async Task DeleteAsync_SiElDocumentoExiste_RetornaTrue()
    {
        var repository = CreateRepository();
        var ticket = NewTicket();
        await repository.CreateAsync(ticket);

        var deleted = await repository.DeleteAsync(ticket.Id!);

        Assert.True(deleted);
        Assert.Null(await repository.GetByIdAsync(ticket.Id!));
    }

    [DockerFact]
    public async Task DeleteAsync_SiElDocumentoNoExiste_RetornaFalse()
    {
        var repository = CreateRepository();

        var deleted = await repository.DeleteAsync(ObjectId.GenerateNewId().ToString());

        Assert.False(deleted);
    }

    [DockerFact]
    public async Task UpdateStatusAsync_CuandoElEstadoCambia_RetornaTrueYSePersiste()
    {
        var repository = CreateRepository();
        var ticket = NewTicket(Tickets.Pending);
        await repository.CreateAsync(ticket);

        var updated = await repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved);

        Assert.True(updated);
        var persisted = await repository.GetByIdAsync(ticket.Id!);
        Assert.Equal(Tickets.Resolved, persisted!.TicketType);
    }

    [DockerFact]
    public async Task UpdateStatusAsync_CuandoElEstadoNoCambia_RetornaFalse()
    {
        // Comportamiento actual: ReplaceOneAsync no modifica nada si el documento
        // es idéntico, así que ModifiedCount queda en 0 y el método devuelve false.
        var repository = CreateRepository();
        var ticket = NewTicket(Tickets.Pending);
        await repository.CreateAsync(ticket);

        var updated = await repository.UpdateStatusAsync(ticket, (int)Tickets.Pending);

        Assert.False(updated);
    }
}
