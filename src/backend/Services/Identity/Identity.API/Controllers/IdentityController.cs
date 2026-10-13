using Identity.Application.Handlers;
using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Identity.API.Controllers;

[ApiController]
[Route("api/identity")]
public class IdentityController(
    LoginHandler loginUseCase,
    RegisterUserHandler registerUserUseCase,
    GetUserByIdHandler getUserByIdUseCase) : ControllerBase
{
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password)) return BadRequest("Email and password are required.");

        var result = await loginUseCase.ExecuteAsync(request, cancellationToken);

        return result.Match(
            loginResult => Ok(loginResult),
            errors => Problem(statusCode: StatusCodes.Status401Unauthorized, title: errors.First().Description)
        );
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)
            || string.IsNullOrWhiteSpace(request.Email)
            || string.IsNullOrWhiteSpace(request.Password)) return BadRequest("Name, email and password are required.");

        var result = await registerUserUseCase.ExecuteAsync(request, cancellationToken);

        return result.Match(
            registeredUser => StatusCode(StatusCodes.Status201Created, registeredUser),
            errors => Problem(statusCode: StatusCodes.Status400BadRequest, title: errors.First().Description)
        );
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetById(
        string userId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(userId)) return BadRequest("User id is required.");

        var result = await getUserByIdUseCase.ExecuteAsync(userId, cancellationToken);

        return result.Match(
            user => Ok(user),
            errors => Problem(statusCode: StatusCodes.Status404NotFound, title: errors.First().Description)
        );
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        CancellationToken cancellationToken)
    {
        var users = await getUserByIdUseCase.ExecuteAllAsync(cancellationToken);
        return Ok(users);
    }
}