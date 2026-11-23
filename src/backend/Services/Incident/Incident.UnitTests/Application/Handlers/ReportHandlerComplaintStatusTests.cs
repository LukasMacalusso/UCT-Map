using ErrorOr;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

/// <summary>
/// Cubre la actualización combinada de estado del ticket y del reclamo
/// (<see cref="ReportHandler.UpdateStatusTicketAsync"/>) y el helper público
/// <see cref="ReportHandler.UpdateStatusComplainAsync"/>.
/// </summary>
public class ReportHandlerComplaintStatusTests
{
    private const string TicketId = "64b000000000000000000001";

    private readonly ITicketRepository _repository = Substitute.For<ITicketRepository>();
    private readonly ReportHandler _handler;

    public ReportHandlerComplaintStatusTests()
    {
        _handler = new ReportHandler(_repository, Substitute.For<ILostObjectRepository>());
    }

    private static Ticket NewTicket(bool withComplaint = true) => new()
    {
        Id = TicketId,
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

    [Fact]
    public async Task UpdateStatusTicketAsync_SinComplainStatus_NoActualizaElReclamo()
    {
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(TicketId, new UpdateStatusReport((int)Tickets.Resolved));

        Assert.False(result.IsError);
        await _repository.DidNotReceiveWithAnyArgs().UpdateStatusComplainAsync(default!, default);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_ConComplainStatusValido_ActualizaAmbos()
    {
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved).Returns(Task.FromResult(true));
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Match).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Resolved, (int)Complainenum.Match));

        Assert.False(result.IsError);
        await _repository.Received(1).UpdateStatusAsync(ticket, (int)Tickets.Resolved);
        await _repository.Received(1).UpdateStatusComplainAsync(ticket, (int)Complainenum.Match);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoElTicketNoCambiaPeroElReclamoSi_RetornaSuccess()
    {
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Pending).Returns(Task.FromResult(false));
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Found).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Pending, (int)Complainenum.Found));

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoElTicketCambiaPeroElReclamoFalla_RetornaSuccess()
    {
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved).Returns(Task.FromResult(true));
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Pickup).Returns(Task.FromResult(false));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Resolved, (int)Complainenum.Pickup));

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoNingunaActualizacionCambiaNada_RetornaFailure()
    {
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Pending).Returns(Task.FromResult(false));
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Claim).Returns(Task.FromResult(false));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Pending, (int)Complainenum.Claim));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.FirstError.Type);
        Assert.Equal("Ticket.UpdateFailed", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoElTicketNoTieneReclamo_NoIntentaActualizarlo()
    {
        var ticket = NewTicket(withComplaint: false);
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Resolved, (int)Complainenum.Match));

        Assert.False(result.IsError);
        await _repository.DidNotReceiveWithAnyArgs().UpdateStatusComplainAsync(default!, default);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_ConComplainStatusInvalido_PeroTicketActualizado_RetornaSuccess()
    {
        // Comportamiento actual: el error del reclamo se ignora si el ticket se actualizó.
        var ticket = NewTicket();
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.UpdateStatusAsync(ticket, (int)Tickets.Resolved).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(
            TicketId, new UpdateStatusReport((int)Tickets.Resolved, 99));

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.DidNotReceiveWithAnyArgs().UpdateStatusComplainAsync(default!, default);
    }

    [Fact]
    public async Task UpdateStatusComplainAsync_ConStatusFueraDelEnum_RetornaValidation()
    {
        var result = await _handler.UpdateStatusComplainAsync(99, NewTicket());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Equal("Ticket.Validation", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateStatusComplainAsync_CuandoElRepositorioFalla_RetornaFailure()
    {
        var ticket = NewTicket();
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Match).Returns(Task.FromResult(false));

        var result = await _handler.UpdateStatusComplainAsync((int)Complainenum.Match, ticket);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.FirstError.Type);
        Assert.Equal("Ticket.UpdateFailed", result.FirstError.Code);
    }

    [Fact]
    public async Task UpdateStatusComplainAsync_CuandoElRepositorioActualiza_RetornaSuccess()
    {
        var ticket = NewTicket();
        _repository.UpdateStatusComplainAsync(ticket, (int)Complainenum.Match).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusComplainAsync((int)Complainenum.Match, ticket);

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).UpdateStatusComplainAsync(ticket, (int)Complainenum.Match);
    }
}
