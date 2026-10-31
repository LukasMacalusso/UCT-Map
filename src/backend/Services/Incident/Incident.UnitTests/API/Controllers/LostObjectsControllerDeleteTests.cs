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
/// Cubre el endpoint DELETE de objetos perdidos: lectura del rol desde el
/// token, mapeo de errores a códigos HTTP y paso del rol al handler.
/// </summary>
public class LostObjectsControllerDeleteTests
{
    private const string ObjectId = "64b000000000000000000001";

    private readonly ILostObjectHandler _handler = Substitute.For<ILostObjectHandler>();
    private readonly LostObjectsController _controller;

    public LostObjectsControllerDeleteTests()
    {
        _controller = new LostObjectsController(_handler);
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
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        var result = await _controller.Delete(ObjectId);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Equal(StatusCodes.Status200OK, ok.StatusCode);
    }

    [Fact]
    public async Task Delete_CuandoNoExiste_Retorna404()
    {
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(
                Error.NotFound("LostObject.NotFound", "LostObject not found")));

        var result = await _controller.Delete(ObjectId);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
        Assert.Equal("LostObject not found", Assert.IsType<ProblemDetails>(problem.Value).Title);
    }

    [Fact]
    public async Task Delete_CuandoNoEstaAutorizado_Retorna400()
    {
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Any<string>())
            .Returns(Task.FromResult<ErrorOr<Success>>(
                Error.Unauthorized("LostObject.Unauthorized", "'Student' is not authorized")));

        var result = await _controller.Delete(ObjectId);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, problem.StatusCode);
    }

    [Fact]
    public async Task Delete_PasaElRolDelTokenAlHandler()
    {
        SetAuthorization(Guid.NewGuid(), "ObjectsOfficer");

        string? capturedRole = null;
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Do<string>(r => capturedRole = r))
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        await _controller.Delete(ObjectId);

        Assert.Equal("ObjectsOfficer", capturedRole);
    }

    [Fact]
    public async Task Delete_CuandoElTokenNoTieneRol_PasaNullAlHandler()
    {
        SetAuthorization(Guid.NewGuid());

        string? capturedRole = "valor-inicial";
        _handler.DeleteAsync(Arg.Any<string>(), Arg.Do<string>(r => capturedRole = r))
            .Returns(Task.FromResult<ErrorOr<Success>>(Result.Success));

        await _controller.Delete(ObjectId);

        Assert.Null(capturedRole);
    }

    [Fact]
    public async Task Search_CuandoElHandlerDevuelveNotFound_Retorna404()
    {
        _handler.SearchAsync(Arg.Any<LostObjectSearchRequest>(), Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ErrorOr<LostObjectPageResponse>>(
                Error.NotFound("LostObject.NotFound", "No encontrado")));

        var result = await _controller.Search(new LostObjectSearchRequest(), CancellationToken.None);

        var problem = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, problem.StatusCode);
    }
}
