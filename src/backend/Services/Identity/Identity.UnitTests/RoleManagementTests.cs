using Identity.Application.DTOs;
using Identity.Domain.Entities;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Authorization;
using Identity.API.Controllers;

namespace Identity.UnitTests;

public sealed class RoleManagementTests
{
    [Fact]
    public async Task AddRoleAsync_AssignsExistingRoleToUser()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var user = await CreateUserAsync(userManager, "teacher@uct.cl");
        await roleManager.CreateAsync(new Role(Role.Teacher));
        var service = new IdentityRoleManagementService(userManager, roleManager);

        var result = await service.AddRoleAsync(user.Id, Role.Teacher);

        var response = Assert.IsType<RoleAssignmentResponse>(result.Value);
        Assert.Contains(Role.Teacher, response.Roles);
    }

    [Fact]
    public async Task RegisterAsync_DoesNotAllowPublicAdminRoleAssignment()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        await roleManager.CreateAsync(new Role(Role.Student));
        await roleManager.CreateAsync(new Role(Role.Admin));
        var service = new IdentityUserRegistrationService(userManager, roleManager);

        var result = await service.RegisterAsync(
            new RegisterRequest("Public User", "public@uct.cl", "Password123!", Role.Admin));

        Assert.Null(result);
        Assert.Null(await userManager.FindByEmailAsync("public@uct.cl"));
    }

    [Fact]
    public async Task ReplaceRolesAsync_ReplacesAssignedRoles()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var user = await CreateUserAsync(userManager, "officer@uct.cl");
        await roleManager.CreateAsync(new Role(Role.Student));
        await roleManager.CreateAsync(new Role(Role.ObjectsOfficer));
        await userManager.AddToRoleAsync(user, Role.Student);
        var service = new IdentityRoleManagementService(userManager, roleManager);

        var result = await service.ReplaceRolesAsync(
            user.Id,
            [Role.ObjectsOfficer]);

        var response = Assert.IsType<RoleAssignmentResponse>(result.Value);
        Assert.Equal([Role.ObjectsOfficer], response.Roles);
    }

    [Fact]
    public async Task SetSuspendedAsync_PreventsLogin()
    {
        using var provider = CreateServices();
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        var user = await CreateUserAsync(userManager, "suspended@uct.cl");
        var service = new IdentityRoleManagementService(userManager, roleManager);

        var result = await service.SetSuspendedAsync(user.Id, true);
        var response = Assert.IsType<RoleAssignmentResponse>(result.Value);
        Assert.True(response.IsSuspended);

        var login = await new IdentityUserAuthenticator(userManager)
            .AuthenticateAsync("suspended@uct.cl", "Password123!");

        Assert.Null(login);

        var reactivated = await service.SetSuspendedAsync(user.Id, false);
        Assert.False(reactivated.Value.IsSuspended);

        var reactivatedLogin = await new IdentityUserAuthenticator(userManager)
            .AuthenticateAsync("suspended@uct.cl", "Password123!");
        Assert.NotNull(reactivatedLogin);
    }

    [Fact]
    public void RoleManagementEndpoints_RequireAdminRole()
    {
        var methods = new[]
        {
            nameof(IdentityController.GetRoles),
            nameof(IdentityController.AddRole),
            nameof(IdentityController.ReplaceRoles),
            nameof(IdentityController.RemoveRole),
            nameof(IdentityController.Suspend),
            nameof(IdentityController.Reactivate)
        };

        foreach (var methodName in methods)
        {
            var method = typeof(IdentityController).GetMethod(methodName);
            var authorize = Assert.Single(method?.GetCustomAttributes(typeof(AuthorizeAttribute), true)
                .Cast<AuthorizeAttribute>()
                ?? []);

            Assert.Equal(Role.Admin, authorize.Roles);
        }
    }

    [Fact]
    public void IdentityEndpoints_RequireAuthenticationExceptLoginAndRegister()
    {
        var controller = typeof(IdentityController);
        var authorize = Assert.Single(controller.GetCustomAttributes(typeof(AuthorizeAttribute), true));

        Assert.Null(controller.GetMethod(nameof(IdentityController.Login))?
            .GetCustomAttributes(typeof(AuthorizeAttribute), true)
            .SingleOrDefault());
        Assert.NotEmpty(controller.GetMethod(nameof(IdentityController.Login))?
            .GetCustomAttributes(typeof(AllowAnonymousAttribute), true) ?? []);
        Assert.NotEmpty(controller.GetMethod(nameof(IdentityController.Register))?
            .GetCustomAttributes(typeof(AllowAnonymousAttribute), true) ?? []);
        Assert.NotNull(authorize);
    }

    private static ServiceProvider CreateServices()
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
}
