using Identity.API.Controllers;
using Identity.Application.DTOs;
using Identity.Application.Handlers;
using Identity.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Identity.UnitTests;

public sealed class IdentityEndpointsUnitTests
{
    [Fact]
    public async Task Login_WhenCredentialsAreMissing_ReturnsBadRequest()
    {
        var controller = CreateController();

        var result = await controller.Login(
            new LoginRequest("", "password"),
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task Login_WhenCredentialsAreInvalid_ReturnsUnauthorized()
    {
        var controller = CreateController(
            authenticator: new StubAuthenticator(null));

        var result = await controller.Login(
            new LoginRequest("user@uct.cl", "wrong-password"),
            CancellationToken.None);

        var response = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status401Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Register_WhenRequiredFieldsAreMissing_ReturnsBadRequest()
    {
        var controller = CreateController();

        var result = await controller.Register(
            new RegisterRequest("", "user@uct.cl", "Password123!"),
            CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task GetById_WhenUserDoesNotExist_ReturnsNotFound()
    {
        var controller = CreateController(
            userQuery: new StubUserQuery(null));

        var result = await controller.GetById(
            "missing-user",
            CancellationToken.None);

        var response = Assert.IsType<ObjectResult>(result);
        Assert.Equal(StatusCodes.Status404NotFound, response.StatusCode);
    }

    private static IdentityController CreateController(
        IUserAuthenticator? authenticator = null,
        IUserQuery? userQuery = null)
    {
        return new IdentityController(
            new LoginHandler(
                authenticator ?? new StubAuthenticator(null),
                new StubTokenGenerator("token")),
            new RegisterUserHandler(
                new StubRegistrationService(null)),
            new GetUserByIdHandler(
                userQuery ?? new StubUserQuery(null)));
    }

    private sealed class StubAuthenticator(LoginResult? result) : IUserAuthenticator
    {
        public Task<LoginResult?> AuthenticateAsync(
            string email,
            string password,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(result);
    }

    private sealed class StubTokenGenerator(string token) : IJwtTokenGenerator
    {
        public Task<string> GenerateAsync(
            LoginResult user,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(token);
    }

    private sealed class StubRegistrationService(RegisteredUserResponse? result)
        : IUserRegistrationService
    {
        public Task<RegisteredUserResponse?> RegisterAsync(
            RegisterRequest request,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(result);
    }

    private sealed class StubUserQuery(RegisteredUserResponse? result) : IUserQuery
    {
        public Task<RegisteredUserResponse?> GetByIdAsync(
            string userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(result);
    }
}
