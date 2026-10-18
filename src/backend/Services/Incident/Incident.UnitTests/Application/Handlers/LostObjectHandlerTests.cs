using ErrorOr;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Domain.Queries;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

public class LostObjectHandlerTests
{
    private readonly ILostObjectRepository _repository;
    private readonly LostObjectHandler _handler;

    public LostObjectHandlerTests()
    {
        _repository = Substitute.For<ILostObjectRepository>();
        _handler = new LostObjectHandler(_repository);
    }

    private static CreateLostObjectRequest ValidRequest(
        string photoUrl = "https://campus.uct.cl/foto.png",
        Guid? structureId = null) =>
        new(
            Title: "Mochila negra",
            Description: "Mochila con libros dejada en la biblioteca",
            Status: (int)Objectenum.Pending,
            PhotoUrl: photoUrl,
            StructureId: structureId ?? Guid.NewGuid());

    // ---------- CreateObjectAsync ----------

    [Fact]
    public async Task CreateObjectAsync_ConPhotoUrlNoEsUrl_RetornaValidation()
    {
        var result = await _handler.CreateObjectAsync(ValidRequest(photoUrl: "no-es-una-url"));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("LostObject.PhotoUrl", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Theory]
    [InlineData("ftp://campus.uct.cl/foto.png")]
    [InlineData("javascript:alert(1)")]
    [InlineData("/ruta/relativa/foto.png")]
    public async Task CreateObjectAsync_ConPhotoUrlDeSchemeInvalido_RetornaValidation(string photoUrl)
    {
        var result = await _handler.CreateObjectAsync(ValidRequest(photoUrl: photoUrl));

        Assert.True(result.IsError);
        Assert.Equal("LostObject.PhotoUrl", result.Errors[0].Code);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(null)]
    public async Task CreateObjectAsync_ConPhotoUrlVacia_NoValidaElFormato(string? photoUrl)
    {
        var result = await _handler.CreateObjectAsync(ValidRequest(photoUrl: photoUrl!));

        Assert.False(result.IsError);
        await _repository.Received(1).CreateAsync(Arg.Any<LostObject>());
    }

    [Fact]
    public async Task CreateObjectAsync_ConStructureIdVacio_RetornaValidation()
    {
        var result = await _handler.CreateObjectAsync(ValidRequest(structureId: Guid.Empty));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("LostObject.StructureId", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs().CreateAsync(default!);
    }

    [Fact]
    public async Task CreateObjectAsync_ConRequestValido_MapeaElEntityYLoPersiste()
    {
        var structureId = Guid.NewGuid();
        var request = new CreateLostObjectRequest(
            Title: "Paraguas azul",
            Description: "Paraguas en el pasillo del piso 2",
            Status: (int)Objectenum.Resolved,
            PhotoUrl: "https://campus.uct.cl/paraguas.jpg",
            StructureId: structureId);

        var result = await _handler.CreateObjectAsync(request);

        Assert.False(result.IsError);
        await _repository.Received(1).CreateAsync(Arg.Is<LostObject>(lo =>
            lo.Title == "Paraguas azul" &&
            lo.Description == "Paraguas en el pasillo del piso 2" &&
            lo.Status == Objectenum.Resolved &&
            lo.PhotoUrl == "https://campus.uct.cl/paraguas.jpg" &&
            lo.StructureRefId == structureId));
    }

    [Fact]
    public async Task CreateObjectAsync_CuandoElRepositorioNoSeteaElId_RetornaCadenaVacia()
    {
        // El Id lo asigna Mongo al insertar; el handler devuelve string.Empty en ese caso.
        var result = await _handler.CreateObjectAsync(ValidRequest());

        Assert.False(result.IsError);
        Assert.Equal(string.Empty, result.Value);
    }

    // ---------- GetByIdAsync ----------

    [Fact]
    public async Task GetByIdAsync_CuandoNoExiste_RetornaNotFound()
    {
        _repository.GetByIdAsync("64b000000000000000000000")
            .Returns(Task.FromResult<LostObject?>(null));

        var result = await _handler.GetByIdAsync("64b000000000000000000000");

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.Errors[0].Type);
        Assert.Equal("LostObject.NotFound", result.Errors[0].Code);
    }

    [Fact]
    public async Task GetByIdAsync_CuandoExiste_MapeaTodosLosCampos()
    {
        var structureId = Guid.NewGuid();
        var reportedAt = new DateTime(2026, 10, 14, 20, 0, 0, DateTimeKind.Utc);
        var entity = new LostObject
        {
            Id = "64b000000000000000000001",
            Title = "Audifonos",
            Description = "Audifonos inalambricos",
            Status = Objectenum.In_Process,
            ReportedAt = reportedAt,
            PhotoUrl = "https://campus.uct.cl/audifonos.jpg",
            StructureRefId = structureId
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<LostObject?>(entity));

        var result = await _handler.GetByIdAsync(entity.Id);

        Assert.False(result.IsError);
        Assert.Equal(new LostObjectResponse(
            "Audifonos",
            "Audifonos inalambricos",
            reportedAt.ToString(),
            nameof(Objectenum.In_Process),
            "https://campus.uct.cl/audifonos.jpg",
            structureId), result.Value);
    }

    // ---------- UpdateStatusAsync ----------

    [Fact]
    public async Task UpdateStatusAsync_ConStatusFueraDelEnum_RetornaValidation()
    {
        var result = await _handler.UpdateStatusAsync("64b000000000000000000000", new UpdateStatus(42));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("LostObject.Validation", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusAsync_CuandoElObjetoNoExiste_RetornaNotFound()
    {
        _repository.GetByIdAsync("64b000000000000000000000")
            .Returns(Task.FromResult<LostObject?>(null));

        var result = await _handler.UpdateStatusAsync("64b000000000000000000000", new UpdateStatus((int)Objectenum.Resolved));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.Errors[0].Type);
        Assert.Equal("LostObject.NotFound", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusAsync_CuandoElRepositorioFalla_RetornaFailure()
    {
        var entity = new LostObject
        {
            Id = "64b000000000000000000000",
            Title = "Mochila",
            Description = "Mochila",
            Status = Objectenum.Pending,
            ReportedAt = DateTime.UtcNow,
            StructureRefId = Guid.NewGuid()
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<LostObject?>(entity));
        _repository.UpdateStatusAsync(entity, (int)Objectenum.Resolved).Returns(Task.FromResult(false));

        var result = await _handler.UpdateStatusAsync(entity.Id!, new UpdateStatus((int)Objectenum.Resolved));

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.Errors[0].Type);
        Assert.Equal("LostObject.UpdateFailed", result.Errors[0].Code);
    }

    [Fact]
    public async Task UpdateStatusAsync_CuandoExiste_RetornaSuccess()
    {
        var entity = new LostObject
        {
            Id = "64b000000000000000000000",
            Title = "Mochila",
            Description = "Mochila",
            Status = Objectenum.Pending,
            ReportedAt = DateTime.UtcNow,
            StructureRefId = Guid.NewGuid()
        };
        _repository.GetByIdAsync(entity.Id).Returns(Task.FromResult<LostObject?>(entity));
        _repository.UpdateStatusAsync(entity, (int)Objectenum.Canceled).Returns(Task.FromResult(true));

        var result = await _handler.UpdateStatusAsync(entity.Id!, new UpdateStatus((int)Objectenum.Canceled));

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).UpdateStatusAsync(entity, (int)Objectenum.Canceled);
    }

    // ---------- SearchAsync ----------

    private static LostObjectSearchRequest SearchRequest(
        string? title = null,
        Guid? structureId = null,
        int? status = null,
        LostObjectSortField sortBy = LostObjectSortField.ReportedAt,
        bool descending = true,
        int page = 1,
        int pageSize = 10) =>
        new(title, structureId, status, sortBy, descending, page, pageSize);

    private static PagedResult<LostObject> EmptyPage(
        int page = 1, int pageSize = 10) =>
        new(Array.Empty<LostObject>(), 0, page, pageSize);

    [Fact]
    public async Task SearchAsync_ConStatusFueraDelEnum_RetornaValidationYNoConsulta()
    {
        var result = await _handler.SearchAsync(SearchRequest(status: 99), CancellationToken.None);

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Validation, result.Errors[0].Type);
        Assert.Equal("LostObject.Status", result.Errors[0].Code);
        await _repository.DidNotReceiveWithAnyArgs()
            .SearchAsync(Arg.Any<LostObjectSearchCriteria>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SearchAsync_SinFiltros_RecortaTitleVacioYUsaValoresPorDefecto()
    {
        LostObjectSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<LostObjectSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<LostObjectSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        await _handler.SearchAsync(SearchRequest(title: "   "), CancellationToken.None);

        Assert.NotNull(captured);
        Assert.Null(captured!.Title);
        Assert.Null(captured.StructureId);
        Assert.Null(captured.Status);
    }

    [Fact]
    public async Task SearchAsync_ConstruyeElCriterio_RecortandoTitleYTopeandoPaginacion()
    {
        LostObjectSearchCriteria? captured = null;
        _repository.SearchAsync(Arg.Any<LostObjectSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(call =>
            {
                captured = call.Arg<LostObjectSearchCriteria>();
                return Task.FromResult(EmptyPage());
            });

        var structureId = Guid.NewGuid();
        await _handler.SearchAsync(
            SearchRequest(title: "  Mochila  ", structureId: structureId, status: (int)Objectenum.Resolved,
                page: 0, pageSize: 50),
            CancellationToken.None);

        Assert.NotNull(captured);
        Assert.Equal("Mochila", captured!.Title);
        Assert.Equal(structureId, captured.StructureId);
        Assert.Equal(Objectenum.Resolved, captured.Status);
        Assert.Equal(1, captured.Page);
        Assert.Equal(10, captured.PageSize);
    }

    [Fact]
    public async Task SearchAsync_MapeaLasEntidadesALaPaginaDeRespuesta()
    {
        var reportedAt = new DateTime(2026, 10, 14, 20, 0, 0, DateTimeKind.Utc);
        var structureId = Guid.NewGuid();
        var entity = new LostObject
        {
            Id = "64b00000000000000000000a",
            Title = "Casco",
            Description = "Casco de bicicleta",
            Status = Objectenum.Resolved,
            ReportedAt = reportedAt,
            PhotoUrl = "https://campus.uct.cl/casco.jpg",
            StructureRefId = structureId
        };
        _repository.SearchAsync(Arg.Any<LostObjectSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(new PagedResult<LostObject>(new[] { entity }, 1, 1, 10)));

        var result = await _handler.SearchAsync(SearchRequest(), CancellationToken.None);

        Assert.False(result.IsError);
        var page = result.Value;
        Assert.Equal(1, page.TotalCount);
        Assert.Equal(1, page.Page);
        Assert.Equal(10, page.PageSize);
        Assert.Equal(1, page.TotalPages);
        var item = Assert.Single(page.Items);
        Assert.Equal("Casco", item.Title);
        Assert.Equal(reportedAt.ToString(), item.Date);
        Assert.Equal(nameof(Objectenum.Resolved), item.Status);
        Assert.Equal("https://campus.uct.cl/casco.jpg", item.PhotoUrl);
        Assert.Equal(structureId, item.StructureId);
    }

    [Fact]
    public async Task SearchAsync_CalculaTotalPagesConElTotalYElPageSize()
    {
        _repository.SearchAsync(Arg.Any<LostObjectSearchCriteria>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(new PagedResult<LostObject>(Array.Empty<LostObject>(), 25, 1, 10)));

        var result = await _handler.SearchAsync(SearchRequest(pageSize: 10), CancellationToken.None);

        Assert.False(result.IsError);
        Assert.Equal(25, result.Value.TotalCount);
        Assert.Equal(3, result.Value.TotalPages);
    }
}
