using ErrorOr;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

/// <summary>
/// Casos de creación de reportes que todavía no estaban cubiertos:
/// tipo de ticket inválido, referencia a un objeto perdido y mapeo del reclamo.
/// </summary>
public class ReportHandlerCreateWithLostObjectTests
{
    private const string LostObjectId = "64b00000000000000000000a";

    private readonly ITicketRepository _repository = Substitute.For<ITicketRepository>();
    private readonly ILostObjectRepository _lostObjectRepository = Substitute.For<ILostObjectRepository>();
    private readonly ReportHandler _handler;

    public ReportHandlerCreateWithLostObjectTests()
    {
        _handler = new ReportHandler(_repository, _lostObjectRepository);
    }

    private static CreateReportRequest Request(
        int ticketType = (int)Tickets.Pending,
        string? lostObjectId = null,
        ComplaintDetails? complaint = null) =>
        new(
            UserRefId: Guid.NewGuid(),
            StructureRefId: Guid.NewGuid(),
            TicketType: ticketType,
            IsActive: true,
            ReportedAt: new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
            LostObjectId: lostObjectId,
            Complaint: complaint);

    private static LostObject ExistingLostObject() => new()
    {
        Id = LostObjectId,
        Title = "Mochila negra",
        Description = "Dejada en la biblioteca",
        Status = Objectenum.Pending,
        ReportedAt = DateTime.UtcNow,
        StructureRefId = Guid.NewGuid()
    };

    [Fact]
    public async Task CreateReportAsync_ConTicketTypeFueraDelEnum_RetornaValidationYNoPersiste()
    {
        var result = await _handler.CreateReportAsync(Request(ticketType: 99));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.Equal("Ticket.Validation", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Fact]
    public async Task CreateReportAsync_ConLostObjectIdExistente_LoPersisteEnElTicket()
    {
        var lostObject = ExistingLostObject();
        _lostObjectRepository.GetByIdAsync(LostObjectId)
            .Returns(Task.FromResult<LostObject?>(lostObject));

        var result = await _handler.CreateReportAsync(Request(lostObjectId: LostObjectId));

        Assert.False(result.IsError);
        await _lostObjectRepository.Received(1).GetByIdAsync(LostObjectId);
        await _repository.Received(1).CreateAsync(Arg.Is<Ticket>(t =>
            t.LostObjectId == LostObjectId));
    }

    [Fact]
    public async Task CreateReportAsync_ConLostObjectIdInexistente_RetornaNotFoundYNoPersiste()
    {
        _lostObjectRepository.GetByIdAsync(LostObjectId)
            .Returns(Task.FromResult<LostObject?>(null));

        var result = await _handler.CreateReportAsync(Request(lostObjectId: LostObjectId));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        Assert.Equal("LostObject.NotFound", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Fact]
    public async Task CreateReportAsync_SinLostObjectId_NoConsultaElRepositorioDeObjetos()
    {
        var result = await _handler.CreateReportAsync(Request());

        Assert.False(result.IsError);
        await _lostObjectRepository.DidNotReceiveWithAnyArgs().GetByIdAsync(default!);
    }

    [Fact]
    public async Task CreateReportAsync_ConReclamo_MapeaElDetalleEmbebido()
    {
        var complaint = new ComplaintDetails
        {
            Title = "Fuga de agua",
            Description = "Baño del segundo piso",
            Status = Complainenum.Claim
        };

        var result = await _handler.CreateReportAsync(Request(complaint: complaint));

        Assert.False(result.IsError);
        await _repository.Received(1).CreateAsync(Arg.Is<Ticket>(t =>
            t.ComplaintDetails != null &&
            t.ComplaintDetails.Title == "Fuga de agua" &&
            t.ComplaintDetails.Description == "Baño del segundo piso" &&
            t.ComplaintDetails.Status == Complainenum.Claim));
    }
}
