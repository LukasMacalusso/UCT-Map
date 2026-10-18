using ErrorOr;
using Incident.API.Controllers;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using NSubstitute;

namespace Incident.UnitTests.API.Controllers;

public class LostObjectsControllerTests
{
    private readonly ILostObjectHandler _handler;
    private readonly LostObjectsController _controller;

    public LostObjectsControllerTests()
    {
        _handler = Substitute.For<ILostObjectHandler>();
        _controller = new LostObjectsController(_handler);
    }

    private static CreateLostObjectRequest ValidRequest() =>
        new("Mochila", "Mochila dejada en sala 3", (int)Objectenum.Pending,
            "https://campus.uct.cl/mochila.png", Guid.NewGuid());

    private static ErrorOr<T> NotFoundError<T>() =>
        Error.NotFound("LostObject.NotFound", "LostObject with ID was not found.");

    private static ErrorOr<T> ValidationError<T>() =>
        Error.Validation("LostObject.Validation", "Invalid status.");

    // ---------- POST ----------

    [Fact]
    public async Task Create_CuandoElHandlerTieneExito_Retorna201ConLocation()
    {
        const string id = "64b00000000000000000000a";
        _handler.CreateObjectAsync(Arg.Any<CreateLostObjectRequest>())
            .Returns(Task.FromResult<ErrorOr<string>>(id));

        var result = await _controller.Create(ValidRequest());

        var created = Assert.IsType<CreatedAtActionResult>(result);
        Assert.Equal(201, created.StatusCode);
        Assert.Equal(nameof(LostObjectsController.GetById), created.ActionName);
        Assert.Equal(id, created.RouteValues?["id"]);
        // El body es un objeto anónimo { id } definido en el API: se lee por reflexión.
        Assert.Equal(id, created.Value?.GetType().GetProperty("id")?.GetValue(created.Value));
    }

    [Fact]
    public async Task Create_CuandoElHandlerValida_Retorna400ConProblemDetails()
    {
        _handler.CreateObjectAsync(Arg.Any<CreateLostObjectRequest>())
            .Returns(Task.FromResult<ErrorOr<string>>(
                Error.Validation("LostObject.PhotoUrl", "Invalid Photo URL format.")));

        var result = await _controller.Create(ValidRequest());

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
        var details = Assert.IsType<ProblemDetails>(problem.Value);
        Assert.Equal("Invalid Photo URL format.", details.Title);
    }

    // ---------- GET by id ----------

    [Fact]
    public async Task GetById_CuandoExiste_Retorna204SinContenido()
    {
        // Comportamiento actual: el handler devuelve los datos pero el controller descarta el body.
        _handler.GetByIdAsync("64b00000000000000000000a")
            .Returns(Task.FromResult<ErrorOr<LostObjectResponse>>(
                new LostObjectResponse("Mochila", "Mochila", "2026-10-14T20:00:00Z",
                    nameof(Objectenum.Pending), "", Guid.NewGuid())));

        var result = await _controller.GetById("64b00000000000000000000a");

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task GetById_CuandoNoExiste_Retorna404()
    {
        _handler.GetByIdAsync("64b00000000000000000000a")
            .Returns(NotFoundError<LostObjectResponse>());

        var result = await _controller.GetById("64b00000000000000000000a");

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
        Assert.Equal("LostObject with ID was not found.", Assert.IsType<ProblemDetails>(problem.Value).Title);
    }

    [Fact]
    public async Task GetById_CuandoHayErrorDeValidacion_Retorna400()
    {
        _handler.GetByIdAsync("64b00000000000000000000a")
            .Returns(ValidationError<LostObjectResponse>());

        var result = await _controller.GetById("64b00000000000000000000a");

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
    }

    // ---------- PATCH status ----------

    [Fact]
    public async Task UpdateStatus_CuandoTieneExito_Retorna204()
    {
        _handler.UpdateStatusAsync("64b00000000000000000000a", Arg.Any<UpdateStatus>())
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        var result = await _controller.UpdateStatus("64b00000000000000000000a", new UpdateStatus((int)Objectenum.Resolved));

        Assert.IsType<NoContentResult>(result);
    }

    [Fact]
    public async Task UpdateStatus_CuandoNoExiste_Retorna404()
    {
        _handler.UpdateStatusAsync("64b00000000000000000000a", Arg.Any<UpdateStatus>())
            .Returns(NotFoundError<Success>());

        var result = await _controller.UpdateStatus("64b00000000000000000000a", new UpdateStatus((int)Objectenum.Resolved));

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }

    [Fact]
    public async Task UpdateStatus_CuandoElStatusEsInvalido_Retorna400()
    {
        _handler.UpdateStatusAsync("64b00000000000000000000a", Arg.Any<UpdateStatus>())
            .Returns(ValidationError<Success>());

        var result = await _controller.UpdateStatus("64b00000000000000000000a", new UpdateStatus(42));

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
    }

    // ---------- GET (search) ----------

    [Fact]
    public async Task Search_CuandoElHandlerTieneExito_Retorna200ConLaPagina()
    {
        var page = new LostObjectPageResponse(
            new List<LostObjectResponse>
            {
                new("Mochila", "Mochila", "2026-10-14T20:00:00Z",
                    nameof(Objectenum.Pending), "https://campus.uct.cl/mochila.png", Guid.NewGuid())
            },
            TotalCount: 1,
            Page: 1,
            PageSize: 10);
        _handler.SearchAsync(Arg.Any<LostObjectSearchRequest>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ErrorOr<LostObjectPageResponse>>(page));

        var result = await _controller.Search(new LostObjectSearchRequest(), CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(200, ok.StatusCode);
        Assert.Same(page, ok.Value);
    }

    [Fact]
    public async Task Search_CuandoElHandlerValida_Retorna400ConProblemDetails()
    {
        _handler.SearchAsync(Arg.Any<LostObjectSearchRequest>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ErrorOr<LostObjectPageResponse>>(
                Error.Validation("LostObject.Status", "Invalid status '99'.")));

        var result = await _controller.Search(
            new LostObjectSearchRequest(Status: 99), CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
        Assert.Equal("Invalid status '99'.", Assert.IsType<ProblemDetails>(problem.Value).Title);
    }
}
