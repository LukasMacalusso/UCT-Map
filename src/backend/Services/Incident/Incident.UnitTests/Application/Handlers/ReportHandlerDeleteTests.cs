using ErrorOr;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

/// <summary>
/// Reglas de autorización del DELETE de reportes/tickets:
/// el dueño puede borrar siempre; cualquier otro usuario necesita uno de los
/// roles Admin, ObjectsOfficer o ComplaintsOfficer.
/// </summary>
public class ReportHandlerDeleteTests
{
    private const string TicketId = "64b000000000000000000001";

    private readonly ITicketRepository _repository = Substitute.For<ITicketRepository>();
    private readonly ReportHandler _handler;

    public ReportHandlerDeleteTests()
    {
        _handler = new ReportHandler(_repository, Substitute.For<ILostObjectRepository>());
    }

    private static Ticket NewTicket(Guid owner, string id = TicketId) => new()
    {
        Id = id,
        UserRefId = owner,
        StructureRefId = Guid.NewGuid(),
        TicketType = Tickets.Pending,
        IsActive = true,
        ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc)
    };

    [Fact]
    public async Task DeleteAsync_CuandoElTicketNoExiste_RetornaNotFoundYNoBorra()
    {
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(null));

        var result = await _handler.DeleteAsync(TicketId, "Admin", Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        Assert.Equal("LostObject.NotFound", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().DeleteAsync(default!);
    }

    [Fact]
    public async Task DeleteAsync_CuandoEsElDuenio_BorraAunqueNoTengaRol()
    {
        var owner = Guid.NewGuid();
        var ticket = NewTicket(owner);
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.DeleteAsync(TicketId).Returns(Task.FromResult(true));

        var result = await _handler.DeleteAsync(TicketId, null!, owner.ToString());

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).DeleteAsync(TicketId);
    }

    [Theory]
    [InlineData("Admin")]
    [InlineData("ObjectsOfficer")]
    [InlineData("ComplaintsOfficer")]
    public async Task DeleteAsync_CuandoNoEsElDuenioPeroTieneRolAutorizado_Borra(string role)
    {
        var ticket = NewTicket(Guid.NewGuid());
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.DeleteAsync(TicketId).Returns(Task.FromResult(true));

        var result = await _handler.DeleteAsync(TicketId, role, Guid.NewGuid().ToString());

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).DeleteAsync(TicketId);
    }

    [Theory]
    [InlineData("Student")]
    [InlineData("Guest")]
    [InlineData("")]
    [InlineData("admin")]
    public async Task DeleteAsync_CuandoNoEsElDuenioYNoTieneRolAutorizado_RetornaUnauthorized(string role)
    {
        var ticket = NewTicket(Guid.NewGuid());
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));

        var result = await _handler.DeleteAsync(TicketId, role, Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Unauthorized, result.FirstError.Type);
        Assert.Equal("LostObject.Unauthorized", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().DeleteAsync(default!);
    }

    [Fact]
    public async Task DeleteAsync_CuandoNoEsElDuenioYElRolEsNulo_RetornaUnauthorized()
    {
        var ticket = NewTicket(Guid.NewGuid());
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));

        var result = await _handler.DeleteAsync(TicketId, null!, Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Unauthorized, result.FirstError.Type);
        await _repository.DidNotReceiveWithAnyArgs().DeleteAsync(default!);
    }

    [Fact]
    public async Task DeleteAsync_CuandoElRepositorioNoBorra_RetornaFailure()
    {
        var owner = Guid.NewGuid();
        var ticket = NewTicket(owner);
        _repository.GetByIdAsync(TicketId).Returns(Task.FromResult<Ticket?>(ticket));
        _repository.DeleteAsync(TicketId).Returns(Task.FromResult(false));

        var result = await _handler.DeleteAsync(TicketId, "Admin", owner.ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.FirstError.Type);
        Assert.Equal("LostObject.UpdateFailed", result.FirstError.Code);
    }
}
