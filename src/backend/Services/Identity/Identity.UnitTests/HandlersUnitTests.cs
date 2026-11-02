using ErrorOr;
using Identity.API.Controllers;
using Identity.Application.DTOs;
using Identity.Application.Handlers;
using Identity.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Identity.UnitTests;

public sealed class HandlersUnitTests
{
    [Fact]
    public async Task RegisterUserHandler_WhenRequestIsInvalid_ReturnsValidationError()
    {
        var handler = new RegisterUserHandler(new StubRegistrationService(null));

        var result = await handler.ExecuteAsync(new RegisterRequest("", "a@uct.cl", "Password123!"));

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Fact]
    public async Task RegisterUserHandler_WhenServiceFails_ReturnsFailure()
    {
        var handler = new RegisterUserHandler(new StubRegistrationService(null));

        var result = await handler.ExecuteAsync(new RegisterRequest("Ana", "a@uct.cl", "Password123!"));

        Assert.Equal(ErrorType.Failure, result.FirstError.Type);
    }

    [Fact]
    public async Task Register_WhenServiceSucceeds_ReturnsCreated()
    {
        var created = new RegisteredUserResponse("1", "Ana", "a@uct.cl", "Student");
        var controller = CreateController(registration: new StubRegistrationService(created));

        var result = await controller.Register(
            new RegisterRequest("Ana", "a@uct.cl", "Password123!"),
            CancellationToken.None);

        var response = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status201Created, response.StatusCode);
        Assert.Equal(created, response.Value);
    }

    [Fact]
    public async Task Register_WhenServiceFails_ReturnsBadRequestProblem()
    {
        var controller = CreateController();

        var result = await controller.Register(
            new RegisterRequest("Ana", "a@uct.cl", "Password123!"),
            CancellationToken.None);

        var response = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status400BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Login_WhenCredentialsAreValid_ReturnsTokenFromGenerator()
    {
        var controller = CreateController(
            authenticator: new StubAuthenticator(new LoginResult("1", "a@uct.cl")));

        var result = await controller.Login(
            new LoginRequest("a@uct.cl", "Password123!"),
            CancellationToken.None);

        var response = Assert.IsType<OkObjectResult>(result);
        Assert.Equal("token", Assert.IsType<LoginResult>(response.Value).Token);
    }

    [Fact]
    public async Task GetById_WhenUserIdIsEmpty_ReturnsBadRequest()
    {
        var controller = CreateController();

        var result = await controller.GetById(" ", CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task GetUserByIdHandler_WhenUserIdIsEmpty_ReturnsValidationError()
    {
        var handler = new GetUserByIdHandler(new StubUserQuery());

        var result = await handler.ExecuteAsync("");

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
    }

    [Theory]
    [InlineData(ErrorType.NotFound, StatusCodes.Status404NotFound)]
    [InlineData(ErrorType.Conflict, StatusCodes.Status409Conflict)]
    [InlineData(ErrorType.Unauthorized, StatusCodes.Status401Unauthorized)]
    [InlineData(ErrorType.Failure, StatusCodes.Status400BadRequest)]
    public async Task RoleEndpoints_MapErrorsToStatusCodes(ErrorType errorType, int expectedStatusCode)
    {
        var handler = new RoleManagementHandler(new StubRoleManagementService(
            Error.Custom((int)errorType, "Test.Error", "Test error.")));
        var controller = CreateController();

        var results = new[]
        {
            await controller.GetRoles("1", handler, CancellationToken.None),
            await controller.AddRole("1", new RoleAssignmentRequest("Teacher"), handler, CancellationToken.None),
            await controller.ReplaceRoles("1", new RoleReplacementRequest(["Teacher"]), handler, CancellationToken.None),
            await controller.Suspend("1", handler, CancellationToken.None),
            await controller.Reactivate("1", handler, CancellationToken.None)
        };

        Assert.All(results, result =>
            Assert.Equal(expectedStatusCode, Assert.IsType<ObjectResult>(result).StatusCode));
    }

    [Fact]
    public async Task RoleEndpoints_WhenServiceSucceeds_ReturnExpectedStatusCodes()
    {
        var response = new RoleAssignmentResponse("1", ["Teacher"], false);
        var handler = new RoleManagementHandler(new StubRoleManagementService(response: response));
        var controller = CreateController();

        var getRoles = await controller.GetRoles("1", handler, CancellationToken.None);
        var addRole = await controller.AddRole("1", new RoleAssignmentRequest("Teacher"), handler, CancellationToken.None);
        var removeRole = await controller.RemoveRole("1", "Teacher", handler, CancellationToken.None);

        Assert.Equal(StatusCodes.Status200OK, Assert.IsType<ObjectResult>(getRoles).StatusCode);
        Assert.Equal(StatusCodes.Status201Created, Assert.IsType<ObjectResult>(addRole).StatusCode);
        Assert.IsType<NoContentResult>(removeRole);
    }

    [Theory]
    [InlineData(ErrorType.NotFound, StatusCodes.Status404NotFound)]
    [InlineData(ErrorType.Failure, StatusCodes.Status400BadRequest)]
    public async Task RemoveRole_MapsErrorsToStatusCodes(ErrorType errorType, int expectedStatusCode)
    {
        var handler = new RoleManagementHandler(new StubRoleManagementService(
            Error.Custom((int)errorType, "Test.Error", "Test error.")));

        var result = await CreateController().RemoveRole("1", "Teacher", handler, CancellationToken.None);

        Assert.Equal(expectedStatusCode, Assert.IsType<ObjectResult>(result).StatusCode);
    }

    [Fact]
    public async Task AddRole_WhenRoleIsEmpty_ReturnsBadRequest()
    {
        var handler = new RoleManagementHandler(new StubRoleManagementService());

        var result = await CreateController().AddRole("1", new RoleAssignmentRequest(""), handler, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public void Health_ReturnsOk()
    {
        Assert.IsType<OkObjectResult>(new HealthController().Get());
    }

    private static IdentityController CreateController(
        IUserAuthenticator? authenticator = null,
        IUserRegistrationService? registration = null)
    {
        return new IdentityController(
            new LoginHandler(
                authenticator ?? new StubAuthenticator(null),
                new StubTokenGenerator()),
            new RegisterUserHandler(registration ?? new StubRegistrationService(null)),
            new GetUserByIdHandler(new StubUserQuery()));
    }

    private sealed class StubAuthenticator(LoginResult? result) : IUserAuthenticator
    {
        public Task<LoginResult?> AuthenticateAsync(
            string email,
            string password,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(result);
    }

    private sealed class StubTokenGenerator : IJwtTokenGenerator
    {
        public Task<string> GenerateAsync(
            LoginResult user,
            CancellationToken cancellationToken = default) =>
            Task.FromResult("token");
    }

    private sealed class StubRegistrationService(RegisteredUserResponse? result)
        : IUserRegistrationService
    {
        public Task<RegisteredUserResponse?> RegisterAsync(
            RegisterRequest request,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(result);
    }

    private sealed class StubUserQuery : IUserQuery
    {
        public Task<IReadOnlyList<RegisteredUserResponse>> GetAllAsync(
            CancellationToken cancellationToken = default) =>
            Task.FromResult<IReadOnlyList<RegisteredUserResponse>>([]);

        public Task<RegisteredUserResponse?> GetByIdAsync(
            string userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult<RegisteredUserResponse?>(null);
    }

    private sealed class StubRoleManagementService(
        Error? error = null,
        RoleAssignmentResponse? response = null) : IRoleManagementService
    {
        private ErrorOr<RoleAssignmentResponse> CreateResult() =>
            error is { } value ? value : response ?? new RoleAssignmentResponse("1", [], false);

        public Task<ErrorOr<RoleAssignmentResponse>> GetRolesAsync(
            string userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(CreateResult());

        public Task<ErrorOr<RoleAssignmentResponse>> AddRoleAsync(
            string userId,
            string role,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(CreateResult());

        public Task<ErrorOr<RoleAssignmentResponse>> ReplaceRolesAsync(
            string userId,
            IReadOnlyList<string> roles,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(CreateResult());

        public Task<ErrorOr<Success>> RemoveRoleAsync(
            string userId,
            string role,
            CancellationToken cancellationToken = default) =>
            Task.FromResult<ErrorOr<Success>>(error is { } value ? value : Result.Success);

        public Task<ErrorOr<RoleAssignmentResponse>> SetSuspendedAsync(
            string userId,
            bool isSuspended,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(CreateResult());
    }
}
