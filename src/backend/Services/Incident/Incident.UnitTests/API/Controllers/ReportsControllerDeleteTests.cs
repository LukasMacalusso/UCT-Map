using ErrorOr;
using Incident.API.Controllers;
using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using NSubstitute;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Incident.UnitTests.API.Controllers;

/// <summary>
/// Cubre el endpoint DELETE de reportes: lectura del token, mapeo de errores
/// a códigos HTTP y paso del rol/usuario al handler.
/// </summary>
public class ReportsControllerDeleteTests
{
    private const string TicketId = "64b000000000000000000001";

    private readonly IReportHandler _handler = Substitute.For<IReportHandler>();
    private readonly ReportsController _controller;

    public ReportsControllerDeleteTests()
    {
        _controller = new ReportsController(_handler);
        SetAuthorization(Guid.NewGuid(), "Admin");
    }

    private void SetAuthorization(Guid userId, string? role = null)
    {
        var claims = new List<Claim> { new(JwtRegisteredClaimNames.Sub, userId.ToString()) };
        if (role is not null) claims.Add(new Claim("role", role));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));
        var token = new JwtSecurityToken(
            claims: claims,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers.Authorization = $"Bearer {new JwtSecurityTokenHandler().WriteToken(token)}";
        _controller.ControllerContext = new ControllerContext { HttpContext = httpContext };
    }

    [Fact]
    public async Task Delete_CuandoTieneExito_Retorna200()
    {
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        var result = await _controller.Delete(TicketId);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(StatusCodes.Status200OK, ok.StatusCode);
    }

    [Fact]
    public async Task Delete_CuandoNoExiste_Retorna404()
    {
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(
                Error.NotFound("LostObject.NotFound", "Ticket not found")));

        var result = await _controller.Delete(TicketId);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
        Assert.Equal("Ticket not found", Assert.IsType<ProblemDetails>(problem.Value).Title);
    }

    [Fact]
    public async Task Delete_CuandoNoEstaAutorizado_Retorna400()
    {
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(
                Error.Unauthorized("LostObject.Unauthorized", "'Student' is not authorized")));

        var result = await _controller.Delete(TicketId);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
        Assert.Equal("'Student' is not authorized", Assert.IsType<ProblemDetails>(problem.Value).Title);
    }

    [Fact]
    public async Task Delete_PasaElRolYElUsuarioDelTokenAlHandler()
    {
        var userId = Guid.NewGuid();
        SetAuthorization(userId, "ComplaintsOfficer");

        string? capturedRole = null;
        string? capturedUser = null;
        _handler.DeleteAsync(
                Arg.Any<string>(),
                Arg.Do<string>(r => capturedRole = r),
                Arg.Do<string>(u => capturedUser = u))
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        await _controller.Delete(TicketId);

        Assert.Equal("ComplaintsOfficer", capturedRole);
        Assert.Equal(userId.ToString(), capturedUser);
    }

    [Fact]
    public async Task Delete_CuandoElTokenNoTieneRol_PasaNullAlHandler()
    {
        SetAuthorization(Guid.NewGuid());

        string? capturedRole = "valor-inicial";
        _handler.DeleteAsync(
                Arg.Any<string>(),
                Arg.Do<string>(r => capturedRole = r),
                Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        await _controller.Delete(TicketId);

        Assert.Null(capturedRole);
    }

    [Fact]
    public async Task Search_CuandoElHandlerDevuelveNotFound_Retorna404()
    {
        _handler.SearchAsync(Arg.Any<TicketSearchRequest>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ErrorOr<TicketPageResponse>>(
                Error.NotFound("Ticket.NotFound", "No encontrado")));

        var result = await _controller.Search(new TicketSearchRequest(), CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }
}
