using System.IdentityModel.Tokens.Jwt;
using Identity.API.Controllers;
using Identity.Application.DTOs;
using Identity.Application.Handlers;
using Identity.Domain.Entities;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Identity.IntegrationTests;

public sealed class IdentityEndpointsIntegrationTests
{
    [Fact]
    public async Task RegisterLoginAndGetById_WorkTogether()
    {
        using var provider = CreateIdentityServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        await roleManager.CreateAsync(new Role(Role.Student));

        var controller = new IdentityController(
            new LoginHandler(
                new IdentityUserAuthenticator(userManager),
                CreateTokenGenerator(userManager)),
            new RegisterUserHandler(
                new IdentityUserRegistrationService(userManager, roleManager)),
            new GetUserByIdHandler(
                new IdentityUserQuery(userManager)));

        var registerResult = await controller.Register(
            new RegisterRequest("Ana Torres", "ana@uct.cl", "Password123!", Role.Student),
            CancellationToken.None);
        var created = Assert.IsType<ObjectResult>(registerResult);
        Assert.Equal(StatusCodes.Status201Created, created.StatusCode);
        var registeredUser = Assert.IsType<RegisteredUserResponse>(created.Value);

        var loginResult = await controller.Login(
            new LoginRequest("ana@uct.cl", "Password123!"),
            CancellationToken.None);
        var login = Assert.IsType<OkObjectResult>(loginResult);
        var loginResponse = Assert.IsType<LoginResult>(login.Value);
        Assert.False(string.IsNullOrWhiteSpace(loginResponse.Token));
        Assert.Equal(
            registeredUser.UserId,
            loginResponse.UserId);
        Assert.NotEmpty(new JwtSecurityTokenHandler()
            .ReadJwtToken(loginResponse.Token!)
            .Claims);

        var getResult = await controller.GetById(
            registeredUser.UserId,
            CancellationToken.None);
        var userResponse = Assert.IsType<OkObjectResult>(getResult);
        Assert.Equal(
            registeredUser.UserId,
            Assert.IsType<RegisteredUserResponse>(userResponse.Value).UserId);
    }

    private static ServiceProvider CreateIdentityServices()
    {
        var services = new ServiceCollection();
        services.AddDbContext<IdentityDbContext>(options =>
            options.UseInMemoryDatabase(Guid.NewGuid().ToString()));
        services.AddIdentityCore<User>()
            .AddRoles<Role>()
            .AddEntityFrameworkStores<IdentityDbContext>();
        return services.BuildServiceProvider();
    }

    private static JwtTokenGenerator CreateTokenGenerator(
        UserManager<User> userManager)
    {
        return new JwtTokenGenerator(
            userManager,
            Options.Create(new JwtSettings
            {
                Key = "12345678901234567890123456789012",
                Issuer = "identity-api",
                Audience = "api-gateway",
                TokenValidationMins = 60
            }));
    }
}
