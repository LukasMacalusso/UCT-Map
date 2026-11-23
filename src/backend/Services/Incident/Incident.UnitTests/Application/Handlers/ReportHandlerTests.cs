using ErrorOr;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Domain.Queries;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

public class ReportHandlerTests
{
    private readonly ITicketRepository _repository;
    private readonly ReportHandler _handler;
    private readonly ILostObjectRepository _lostObjectRepository;

    public ReportHandlerTests()
    {
        _repository = Substitute.For<ITicketRepository>();
        _lostObjectRepository = Substitute.For<ILostObjectRepository>();
        _handler = new ReportHandler(_repository, _lostObjectRepository);
    }

    private static CreateReportRequest ValidRequest(
        Guid? userRefId = null,
        Guid? structureRefId = null,
        int ticketType = (int)Tickets.Pending) =>
        new(
            UserRefId: userRefId ?? Guid.NewGuid(),
            StructureRefId: structureRefId ?? Guid.NewGuid(),
            TicketType: ticketType,
            IsActive: true,
            ReportedAt: new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc));

    // ---------- CreateReportAsync ----------

    [Fact]
    public async Task CreateReportAsync_ConUserRefIdVacio_RetornaValidation()
    {
        var result = await _handler.CreateReportAsync(ValidRequest(userRefId: Guid.Empty));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("Report.UserRefId", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Fact]
    public async Task CreateReportAsync_ConStructureRefIdVacio_RetornaValidation()
    {
        var result = await _handler.CreateReportAsync(ValidRequest(structureRefId: Guid.Empty));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("Report.StructureRefId", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Fact]
    public async Task CreateReportAsync_ConRequestValido_MapeaElEntityYLoPersiste()
    {
        var userRefId = Guid.NewGuid();
        var structureRefId = Guid.NewGuid();
        var reportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc);

        var result = await _handler.CreateReportAsync(new CreateReportRequest(
            UserRefId: userRefId,
            StructureRefId: structureRefId,
            TicketType: (int)Tickets.In_Process,
            IsActive: false,
            ReportedAt: reportedAt));

        Assert.False(result.IsError);
        await _repository.Received(1).CreateAsync(Arg.Is<Ticket>(t =>
            t.UserRefId == userRefId &&
            t.StructureRefId == structureRefId &&
            t.TicketType == Tickets.In_Process &&
            t.IsActive == false &&
            t.ReportedAt == reportedAt));
    }

    [Fact]
    public async Task CreateReportAsync_CuandoElRepositorioNoSeteaElId_RetornaCadenaVacia()
    {
        var result = await _handler.CreateReportAsync(ValidRequest());

        Assert.False(result.IsError);
        Assert.Equal(string.Empty, result.Value);
    }

    // ---------- GetByIdAsync ----------

    [Fact]
    public async Task GetByIdAsync_CuandoNoExiste_RetornaNotFound()
    {
        _repository.GetByIdAsync("64b000000000000000000000")
            .Returns(Task.FromResult<Ticket?>(null));

        var result = await _handler.GetByIdAsync("64b000000000000000000000");

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.Errors[0].Type);
        Assert.Equal("Report.NotFound", result.Errors[0].Code);
    }

    [Fact]
    public async Task GetByIdAsync_CuandoExiste_MapeaTodosLosCampos()
    {
        var userRefId = Guid.NewGuid();
        var structureRefId = Guid.NewGuid();
        var reportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc);
        var complaint = new ComplaintDetails
        {
            Title = "Reclamo",
            Description = "Objeto no devuelto",
            Status = Complainenum.Claim
        };

        var entity = new Ticket
        {
            Id = "64b000000000000000000001",
            UserRefId = userRefId,
            StructureRefId = structureRefId,
            TicketType = Tickets.Resolved,
            IsActive = true,
            ReportedAt = reportedAt,
            ComplaintDetails = complaint,
            LostObjectId = "64b000000000000000000002"
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<Ticket?>(entity));

        var result = await _handler.GetByIdAsync(entity.Id!);

        Assert.False(result.IsError);
        Assert.Equal(new TicketResponse(
            entity.Id!,
            userRefId,
            structureRefId,
            Tickets.Resolved,
            true,
            reportedAt,
            complaint,
            "64b000000000000000000002"), result.Value);
    }

    [Fact]
    public async Task GetByIdAsync_CuandoNoTieneDetalles_OpcionalesSonNulos()
    {
        var entity = new Ticket
        {
            Id = "64b000000000000000000003",
            UserRefId = Guid.NewGuid(),
            StructureRefId = Guid.NewGuid(),
            TicketType = Tickets.Pending,
            IsActive = true,
            ReportedAt = DateTime.UtcNow
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<Ticket?>(entity));

        var result = await _handler.GetByIdAsync(entity.Id!);

        Assert.False(result.IsError);
        Assert.Null(result.Value.ComplaintDetails);
        Assert.Null(result.Value.LostObjectId);
    }

    // ---------- UpdateStatusTicketAsync ----------

    [Fact]
    public async Task UpdateStatusTicketAsync_ConStatusFueraDelEnum_RetornaValidation()
    {
        var result = await _handler.UpdateStatusTicketAsync("64b000000000000000000000", new UpdateStatusReport(99));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("Ticket.Validation", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoNoExiste_RetornaNotFound()
    {
        _repository.GetByIdAsync("64b000000000000000000000")
            .Returns(Task.FromResult<Ticket?>(null));

        var result = await _handler.UpdateStatusTicketAsync("64b000000000000000000000", new UpdateStatusReport((int)Tickets.Resolved));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.Errors[0].Type);
        Assert.Equal("Ticket.NotFound", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoElRepositorioFalla_RetornaFailure()
    {
        var entity = new Ticket
        {
            Id = "64b000000000000000000000",
            UserRefId = Guid.NewGuid(),
            StructureRefId = Guid.NewGuid(),
            TicketType = Tickets.Pending,
            IsActive = true,
            ReportedAt = DateTime.UtcNow
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<Ticket?>(entity));
        _repository.UpdateStatusAsync(entity, (int)Tickets.Resolved).Returns(Task.FromResult(false));

        var result = await _handler.UpdateStatusTicketAsync(entity.Id!, new UpdateStatusReport((int)Tickets.Resolved));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.Errors[0].Type);
        Assert.Equal("Ticket.UpdateFailed", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusTicketAsync_CuandoExiste_RetornaSuccess()
    {
        var entity = new Ticket
        {
            Id = "64b000000000000000000000",
            UserRefId = Guid.NewGuid(),
            StructureRefId = Guid.NewGuid(),
            TicketType = Tickets.Pending,
            IsActive = true,
            ReportedAt = DateTime.UtcNow
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<Ticket?>(entity));
        _repository.UpdateStatusAsync(entity, (int)Tickets.Dismissed).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusTicketAsync(entity.Id!, new UpdateStatusReport((int)Tickets.Dismissed));

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).UpdateStatusAsync(entity, (int)Tickets.Dismissed);
    }

    // ---------- SearchAsync ----------

    private static TicketSearchRequest SearchRequest(
        Guid? userRefId = null,
        Guid? structureRefId = null,
        int? type = null,
        bool? isActive = null,
        TicketSortBy sortBy = TicketSortBy.ReportedAt,
        GeoPoint? location = null,
        string? lostObjectId = null,
        ComplaintSearchRequest? complaintDetails = null,
        bool descending = true,
        int page = 1,
        int pageSize = 10) =>
        new(userRefId, structureRefId, type, isActive, sortBy, location, lostObjectId,
            complaintDetails, descending, page, pageSize);

    private static PagedResult<Ticket> EmptyPage(int page = 1, int pageSize = 10) =>
        new(Array.Empty<Ticket>(), 0, page, pageSize);

    [Fact]
    public async Task SearchAsync_ConTypeFueraDelEnum_RetornaValidationYNoConsulta()
    {
        var result = await _handler.SearchAsync(SearchRequest(type: 99), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("Ticket.Type", result.Errors[0].Code);
        Assert.Equal("Invalid type '99'.", result.Errors[0].Description);
        await _repository.DidNotReceiveWithAnyArgs()
            .SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SearchAsync_ConComplaintStatusFueraDelEnum_RetornaValidationYNoConsulta()
    {
        var request = SearchRequest(complaintDetails: new ComplaintSearchRequest(Status: 99));

        var result = await _handler.SearchAsync(request, CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("Ticket.ComplaintStatus", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs()
            .SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SearchAsync_SinFiltros_RecortaLasCadenasVaciasYNoAplicaReclamo()
    {
        TicketSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<TicketSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        await _handler.SearchAsync(
            SearchRequest(lostObjectId: "   ", complaintDetails: new ComplaintSearchRequest(Title: "   ")),
            CancellationToken.None);

        Assert.NotNull(captured);
        Assert.Null(captured!.UserRefId);
        Assert.Null(captured.StructureRefId);
        Assert.Null(captured.Type);
        Assert.Null(captured.IsActive);
        Assert.Null(captured.LostObjectId);
        Assert.Null(captured.ComplaintDetails);
    }

    [Fact]
    public async Task SearchAsync_ConstruyeElCriterio_RecortandoYTopeandoPaginacion()
    {
        TicketSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<TicketSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        var userRefId = Guid.NewGuid();
        var structureRefId = Guid.NewGuid();
        await _handler.SearchAsync(
            SearchRequest(userRefId: userRefId, structureRefId: structureRefId, type: (int)Tickets.Resolved,
                isActive: false, lostObjectId: "  64b00000000000000000000f  ", page: 0, pageSize: 50),
            CancellationToken.None);

        Assert.NotNull(captured);
        Assert.Equal(userRefId, captured!.UserRefId);
        Assert.Equal(structureRefId, captured.StructureRefId);
        Assert.Equal(Tickets.Resolved, captured.Type);
        Assert.False(captured.IsActive);
        Assert.Equal("64b00000000000000000000f", captured.LostObjectId);
        Assert.Equal(TicketSortBy.ReportedAt, captured.SortBy);
        Assert.True(captured.Descending);
        Assert.Equal(1, captured.Page);
        Assert.Equal(10, captured.PageSize);
    }

    [Fact]
    public async Task SearchAsync_ConReclamoParcial_SoloConservaLosCamposConValor()
    {
        TicketSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<TicketSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        await _handler.SearchAsync(
            SearchRequest(complaintDetails: new ComplaintSearchRequest(Title: " Fuga de agua ")),
            CancellationToken.None);

        Assert.NotNull(captured);
        var complaint = captured!.ComplaintDetails;
        Assert.NotNull(complaint);
        Assert.Equal("Fuga de agua", complaint!.Title);
        Assert.Null(complaint.Description);
        Assert.Null(complaint.Status);
    }

    [Fact]
    public async Task SearchAsync_ConReclamo_ConvierteElStatusAlEnum()
    {
        TicketSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<TicketSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        await _handler.SearchAsync(
            SearchRequest(complaintDetails: new ComplaintSearchRequest(
                Description: "  Baño del 2do piso  ", Status: (int)Complainenum.Match)),
            CancellationToken.None);

        Assert.NotNull(captured);
        var complaint = captured!.ComplaintDetails;
        Assert.NotNull(complaint);
        Assert.Equal("Baño del 2do piso", complaint!.Description);
        Assert.Equal(Complainenum.Match, complaint.Status);
    }

    [Fact]
    public async Task SearchAsync_MapeaLasEntidadesALaPaginaDeRespuesta()
    {
        var userRefId = Guid.NewGuid();
        var structureRefId = Guid.NewGuid();
        var reportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc);
        var complaint = new ComplaintDetails
        {
            Title = "Fuga",
            Description = "Baño del 2do piso",
            Status = Complainenum.Claim
        };
        var entity = new Ticket
        {
            Id = "64b00000000000000000000a",
            UserRefId = userRefId,
            StructureRefId = structureRefId,
            TicketType = Tickets.In_Process,
            IsActive = true,
            ReportedAt = reportedAt,
            ComplaintDetails = complaint,
            LostObjectId = "64b00000000000000000000b"
        };
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(new PagedResult<Ticket>(new[] { entity }, 1, 1, 10)));

        var result = await _handler.SearchAsync(SearchRequest(), CancellationToken.None);

        Assert.False(result.IsError);
        var page = result.Value;
        Assert.Equal(1, page.TotalCount);
        Assert.Equal(1, page.Page);
        Assert.Equal(10, page.PageSize);
        Assert.Equal(1, page.TotalPages);
        var item = Assert.Single(page.Items);
        Assert.Equal(entity.Id, item.Id);
        Assert.Equal(userRefId, item.UserRefId);
        Assert.Equal(structureRefId, item.StructureRefId);
        Assert.Equal(Tickets.In_Process, item.TicketType);
        Assert.True(item.IsActive);
        Assert.Equal(reportedAt, item.ReportedAt);
        Assert.Same(complaint, item.ComplaintDetails);
        Assert.Equal(entity.LostObjectId, item.LostObjectId);
    }

    [Fact]
    public async Task SearchAsync_CalculaTotalPagesConElTotalYElPageSize()
    {
        _repository.SearchAsync(Arg.Any<TicketSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(new PagedResult<Ticket>(Array.Empty<Ticket>(), 25, 1, 10)));

        var result = await _handler.SearchAsync(SearchRequest(pageSize: 10), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(25, result.Value.TotalCount);
        Assert.Equal(3, result.Value.TotalPages);
    }
}
