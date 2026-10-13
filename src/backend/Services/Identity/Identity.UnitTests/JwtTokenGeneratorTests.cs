using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Identity.Application.DTOs;
using Identity.Domain.Entities;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace Identity.UnitTests;

public sealed class JwtTokenGeneratorTests
{
    [Fact]
    public async Task GenerateAsync_WhenUserHasRole_IncludesExplicitRoleClaim()
    {
        using var provider = CreateIdentityServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var user = await CreateUserAsync(userManager, "student@uct.cl");

        await roleManager.CreateAsync(new Role(Role.Student));
        await userManager.AddToRoleAsync(user, Role.Student);

        var token = await CreateGenerator(userManager).GenerateAsync(
            new LoginResult(user.Id, user.Email!));
        var claims = new JwtSecurityTokenHandler().ReadJwtToken(token).Claims.ToList();

        Assert.Contains(claims, claim => claim.Type == "role" && claim.Value == Role.Student);
        Assert.Contains(claims, claim => claim.Type == ClaimTypes.Role && claim.Value == Role.Student);
    }

    [Fact]
    public async Task GenerateAsync_WhenUserHasAllSupportedRoles_IncludesEveryRole()
    {
        using var provider = CreateIdentityServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var user = await CreateUserAsync(userManager, "all-roles@uct.cl");
        var expectedRoles = new[]
        {
            Role.Admin,
            Role.Student,
            Role.Teacher,
            Role.ObjectsOfficer,
            Role.ComplaintsOfficer
        };

        foreach (var role in expectedRoles)
        {
            await roleManager.CreateAsync(new Role(role));
        }

        await userManager.AddToRolesAsync(user, expectedRoles);

        var token = await CreateGenerator(userManager).GenerateAsync(
            new LoginResult(user.Id, user.Email!));
        var roleClaims = new JwtSecurityTokenHandler()
            .ReadJwtToken(token)
            .Claims
            .Where(claim => claim.Type == "role")
            .Select(claim => claim.Value)
            .ToHashSet();

        Assert.Equal(expectedRoles.ToHashSet(), roleClaims);
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

    private static async Task<User> CreateUserAsync(
        UserManager<User> userManager,
        string email)
    {
        var user = User.Create("Test User", email);
        var result = await userManager.CreateAsync(user, "Password123!");
        Assert.True(result.Succeeded);
        return user;
    }

    private static JwtTokenGenerator CreateGenerator(UserManager<User> userManager)
    {
        return new JwtTokenGenerator(userManager, Options.Create(new JwtSettings
        {
            Key = "12345678901234567890123456789012",
            Issuer = "identity-api",
            Audience = "api-gateway",
            TokenValidationMins = 60
        }));
    }
}
