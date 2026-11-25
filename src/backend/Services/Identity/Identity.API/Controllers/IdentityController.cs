using Identity.Application.Handlers;
using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using ErrorOr;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Identity.API.Controllers;

[ApiController]
[Route("api/identity")]
[Authorize]
public class IdentityController(
    LoginHandler loginUseCase,
    RegisterUserHandler registerUserUseCase,
    GetUserByIdHandler getUserByIdUseCase) : ControllerBase
{
    private const string SubjectClaimType = "sub";

    private string CurrentUserId =>
        User?.FindFirstValue(SubjectClaimType)
        ?? User?.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? string.Empty;

    private bool CurrentUserIsAdmin => User?.IsInRole(Role.Admin) == true;

    [AllowAnonymous]
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

    [AllowAnonymous]
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

        var result = await getUserByIdUseCase.ExecuteAsync(
            userId,
            CurrentUserId,
            CurrentUserIsAdmin,
            cancellationToken);

        return result.Match<IActionResult>(
            user => Ok(user),
            errors => Problem(statusCode: ToStatusCode(errors.First().Type), title: errors.First().Description));
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(
        CancellationToken cancellationToken)
    {
        var users = await getUserByIdUseCase.ExecuteAllAsync(CurrentUserIsAdmin, cancellationToken);
        return Ok(users);
    }

    [Authorize(Roles = Role.Admin)]
    [HttpGet("{userId}/roles")]
    public async Task<IActionResult> GetRoles(
        string userId,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        var result = await roleManagementHandler.ExecuteGetAsync(userId, cancellationToken);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [Authorize(Roles = Role.Admin)]
    [HttpPost("{userId}/roles")]
    public async Task<IActionResult> AddRole(
        string userId,
        [FromBody] RoleAssignmentRequest request,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Role)) return BadRequest("Role is required.");

        var result = await roleManagementHandler.ExecuteAddAsync(userId, request.Role, cancellationToken);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [Authorize(Roles = Role.Admin)]
    [HttpPut("{userId}/roles")]
    public async Task<IActionResult> ReplaceRoles(
        string userId,
        [FromBody] RoleReplacementRequest request,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        var result = await roleManagementHandler.ExecuteReplaceAsync(CurrentUserId, userId, request.Roles, cancellationToken);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [Authorize(Roles = Role.Admin)]
    [HttpDelete("{userId}/roles/{role}")]
    public async Task<IActionResult> RemoveRole(
        string userId,
        string role,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        var result = await roleManagementHandler.ExecuteRemoveAsync(CurrentUserId, userId, role, cancellationToken);
        return result.Match<IActionResult>(
            _ => NoContent(),
            errors => Problem(statusCode: ToStatusCode(errors.First().Type), title: errors.First().Description));
    }

    [Authorize(Roles = Role.Admin)]
    [HttpPost("{userId}/suspension")]
    public async Task<IActionResult> Suspend(
        string userId,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        var result = await roleManagementHandler.ExecuteSetSuspendedAsync(CurrentUserId, userId, true, cancellationToken);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [Authorize(Roles = Role.Admin)]
    [HttpDelete("{userId}/suspension")]
    public async Task<IActionResult> Reactivate(
        string userId,
        [FromServices] RoleManagementHandler roleManagementHandler,
        CancellationToken cancellationToken)
    {
        var result = await roleManagementHandler.ExecuteSetSuspendedAsync(CurrentUserId, userId, false, cancellationToken);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    private IActionResult ToActionResult<T>(ErrorOr<T> result, int successStatusCode)
    {
        return result.Match<IActionResult>(
            value => new ObjectResult(value) { StatusCode = successStatusCode },
            errors => Problem(statusCode: ToStatusCode(errors.First().Type), title: errors.First().Description));
    }

    private static int ToStatusCode(ErrorType errorType) => errorType switch
    {
        ErrorType.NotFound => StatusCodes.Status404NotFound,
        ErrorType.Conflict => StatusCodes.Status409Conflict,
        ErrorType.Unauthorized => StatusCodes.Status401Unauthorized,
        ErrorType.Forbidden => StatusCodes.Status403Forbidden,
        _ => StatusCodes.Status400BadRequest
    };
}