using System.Security.Claims;
using ErrorOr;
using Identity.API.Controllers;
using Identity.Application.DTOs;
using Identity.Application.Handlers;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Identity.UnitTests;

public sealed class AdminProtectionTests
{
    [Fact]
    public async Task ExecuteSetSuspendedAsync_WhenAdminSuspendsSelf_ReturnsForbidden()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteSetSuspendedAsync("admin-1", "admin-1", true);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.False(service.WasCalled);
    }

    [Fact]
    public async Task ExecuteSetSuspendedAsync_WhenAdminReactivatesSelf_CallsService()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteSetSuspendedAsync("admin-1", "admin-1", false);

        Assert.False(result.IsError);
        Assert.True(service.WasCalled);
    }

    [Theory]
    [InlineData("Admin")]
    [InlineData("admin")]
    public async Task ExecuteRemoveAsync_WhenAdminRemovesOwnAdminRole_ReturnsForbidden(string role)
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteRemoveAsync("admin-1", "admin-1", role);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.False(service.WasCalled);
    }

    [Fact]
    public async Task ExecuteRemoveAsync_WhenAdminRemovesOtherRoleFromSelf_CallsService()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteRemoveAsync("admin-1", "admin-1", Role.Teacher);

        Assert.False(result.IsError);
        Assert.True(service.WasCalled);
    }

    [Fact]
    public async Task ExecuteReplaceAsync_WhenAdminDropsOwnAdminRole_ReturnsForbidden()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteReplaceAsync("admin-1", "admin-1", [Role.Teacher]);

        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.False(service.WasCalled);
    }

    [Fact]
    public async Task ExecuteReplaceAsync_WhenAdminKeepsOwnAdminRole_CallsService()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteReplaceAsync("admin-1", "admin-1", [Role.Admin, Role.Teacher]);

        Assert.False(result.IsError);
        Assert.True(service.WasCalled);
    }

    [Fact]
    public async Task RoleHandlers_WhenActingUserIsMissing_ReturnUnauthorized()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var suspend = await handler.ExecuteSetSuspendedAsync("", "user-1", true);
        var remove = await handler.ExecuteRemoveAsync(" ", "user-1", Role.Teacher);
        var replace = await handler.ExecuteReplaceAsync("", "user-1", [Role.Teacher]);

        Assert.Equal(ErrorType.Unauthorized, suspend.FirstError.Type);
        Assert.Equal(ErrorType.Unauthorized, remove.FirstError.Type);
        Assert.Equal(ErrorType.Unauthorized, replace.FirstError.Type);
        Assert.False(service.WasCalled);
    }

    [Fact]
    public async Task SetSuspendedAsync_WhenUserIsLastActiveAdmin_ReturnsConflict()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var admin = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);

        var result = await service.SetSuspendedAsync(admin.Id, true);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.False((await userManager.FindByIdAsync(admin.Id))!.IsSuspended);
    }

    [Fact]
    public async Task SetSuspendedAsync_WhenAnotherActiveAdminExists_SuspendsAdmin()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var admin = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);
        await CreateUserAsync(userManager, "other-admin@uct.cl", Role.Admin);

        var result = await service.SetSuspendedAsync(admin.Id, true);

        Assert.True(result.Value.IsSuspended);
    }

    [Fact]
    public async Task RemoveRoleAsync_WhenOtherAdminIsSuspended_KeepsLastActiveAdmin()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var admin = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);
        var suspendedAdmin = await CreateUserAsync(userManager, "suspended-admin@uct.cl", Role.Admin);
        suspendedAdmin.SetSuspended(true);
        await userManager.UpdateAsync(suspendedAdmin);

        var result = await service.RemoveRoleAsync(admin.Id, Role.Admin);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.True(await userManager.IsInRoleAsync(admin, Role.Admin));
    }

    [Fact]
    public async Task ReplaceRolesAsync_WhenRemovingLastActiveAdmin_ReturnsConflict()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var admin = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);

        var result = await service.ReplaceRolesAsync(admin.Id, [Role.Teacher]);

        Assert.Equal(ErrorType.Conflict, result.FirstError.Type);
        Assert.True(await userManager.IsInRoleAsync(admin, Role.Admin));
    }

    [Fact]
    public async Task ReplaceRolesAsync_WhenAnotherActiveAdminExists_RemovesAdminRole()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var admin = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);
        await CreateUserAsync(userManager, "other-admin@uct.cl", Role.Admin);

        var result = await service.ReplaceRolesAsync(admin.Id, [Role.Teacher]);

        Assert.Equal([Role.Teacher], result.Value.Roles);
    }

    [Fact]
    public async Task ReplaceRolesAsync_WhenRoleListIsEmpty_ReturnsValidationError()
    {
        using var provider = CreateServices();
        var (userManager, service) = await CreateServiceAsync(provider);
        var teacher = await CreateUserAsync(userManager, "teacher@uct.cl", Role.Teacher);

        var result = await service.ReplaceRolesAsync(teacher.Id, [" ", ""]);

        Assert.Equal(ErrorType.Validation, result.FirstError.Type);
        Assert.True(await userManager.IsInRoleAsync(teacher, Role.Teacher));
    }

    [Fact]
    public async Task ExecuteReplaceAsync_WhenRolesAreNull_PassesEmptyListToService()
    {
        var service = new RecordingRoleManagementService();
        var handler = new RoleManagementHandler(service);

        var result = await handler.ExecuteReplaceAsync("admin-1", "user-1", null!);

        Assert.False(result.IsError);
        Assert.Empty(service.LastRoles!);
    }

    [Fact]
    public async Task RefreshAsync_WhenUserIsActive_UsesCurrentDatabaseRoles()
    {
        using var provider = CreateServices();
        var (userManager, _) = await CreateServiceAsync(provider);
        var user = await CreateUserAsync(userManager, "teacher@uct.cl", Role.Teacher);
        var validator = new ActiveUserPrincipalValidator(userManager);

        var principal = await validator.RefreshAsync(CreatePrincipal(user.Id, Role.Admin));

        Assert.NotNull(principal);
        Assert.True(principal.IsInRole(Role.Teacher));
        Assert.False(principal.IsInRole(Role.Admin));
        Assert.Equal(user.Id, principal.FindFirstValue("sub"));
    }

    [Fact]
    public async Task RefreshAsync_WhenUserIsSuspended_ReturnsNull()
    {
        using var provider = CreateServices();
        var (userManager, _) = await CreateServiceAsync(provider);
        var user = await CreateUserAsync(userManager, "admin@uct.cl", Role.Admin);
        user.SetSuspended(true);
        await userManager.UpdateAsync(user);
        var validator = new ActiveUserPrincipalValidator(userManager);

        var principal = await validator.RefreshAsync(CreatePrincipal(user.Id, Role.Admin));

        Assert.Null(principal);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("missing-user")]
    public async Task RefreshAsync_WhenUserCannotBeFound_ReturnsNull(string? userId)
    {
        using var provider = CreateServices();
        var (userManager, _) = await CreateServiceAsync(provider);
        var validator = new ActiveUserPrincipalValidator(userManager);

        var principal = await validator.RefreshAsync(CreatePrincipal(userId, Role.Admin));

        Assert.Null(principal);
    }

    [Fact]
    public async Task GetById_WhenStudentRequestsAnotherUser_ReturnsForbidden()
    {
        var controller = CreateQueryController(new RegisteredUserResponse("user-2", "Luis Perez", "luis@uct.cl"));
        controller.ControllerContext = TestUserContext.For("user-1", Role.Student);

        var result = await controller.GetById("user-2", CancellationToken.None);

        Assert.Equal(StatusCodes.Status403Forbidden, Assert.IsType<ObjectResult>(result).StatusCode);
    }

    [Fact]
    public async Task GetById_WhenStudentRequestsOwnProfile_ReturnsUser()
    {
        var user = new RegisteredUserResponse("user-1", "Ana Torres", "ana@uct.cl", Role.Student);
        var controller = CreateQueryController(user);
        controller.ControllerContext = TestUserContext.For("user-1", Role.Student);

        var result = await controller.GetById("user-1", CancellationToken.None);

        Assert.Equal(user, Assert.IsType<OkObjectResult>(result).Value);
    }

    [Fact]
    public async Task GetAll_WhenRequesterIsNotAdmin_HidesSuspendedUsers()
    {
        var controller = CreateQueryController(users: Users());
        controller.ControllerContext = TestUserContext.For("user-1", Role.Student);

        var result = await controller.GetAll(CancellationToken.None);

        var users = Assert.IsAssignableFrom<IReadOnlyList<RegisteredUserResponse>>(
            Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(["1"], users.Select(user => user.UserId));
    }

    [Fact]
    public async Task GetAll_WhenRequesterIsAdmin_ReturnsSuspendedUsers()
    {
        var controller = CreateQueryController(users: Users());
        controller.ControllerContext = TestUserContext.Admin();

        var result = await controller.GetAll(CancellationToken.None);

        var users = Assert.IsAssignableFrom<IReadOnlyList<RegisteredUserResponse>>(
            Assert.IsType<OkObjectResult>(result).Value);
        Assert.Equal(2, users.Count);
    }

    private static ClaimsPrincipal CreatePrincipal(string? userId, string role)
    {
        var claims = new List<Claim> { new("role", role), new(ClaimTypes.Role, role) };
        if (userId is not null) claims.Add(new Claim("sub", userId));
        return new ClaimsPrincipal(new ClaimsIdentity(claims, "Bearer", "sub", "role"));
    }

    private static RegisteredUserResponse[] Users() =>
    [
        new("1", "Ana Torres", "ana@uct.cl", Role.Student),
        new("2", "Luis Perez", "luis@uct.cl", Role.Teacher, IsSuspended: true)
    ];

    private static IdentityController CreateQueryController(
        RegisteredUserResponse? user = null,
        IReadOnlyList<RegisteredUserResponse>? users = null) =>
        new(
            new LoginHandler(null!, null!),
            new RegisterUserHandler(null!),
            new GetUserByIdHandler(new StubUserQuery(user, users ?? [])));

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

    private static async Task<(UserManager<User>, IdentityRoleManagementService)> CreateServiceAsync(
        ServiceProvider provider)
    {
        var userManager = provider.GetRequiredService<UserManager<User>>();
        var roleManager = provider.GetRequiredService<RoleManager<Role>>();
        await roleManager.CreateAsync(new Role(Role.Admin));
        await roleManager.CreateAsync(new Role(Role.Teacher));
        return (userManager, new IdentityRoleManagementService(userManager, roleManager));
    }

    private static async Task<User> CreateUserAsync(
        UserManager<User> userManager,
        string email,
        string role)
    {
        var user = User.Create("Test User", email);
        Assert.True((await userManager.CreateAsync(user, "Password123!")).Succeeded);
        Assert.True((await userManager.AddToRoleAsync(user, role)).Succeeded);
        return user;
    }

    private sealed class RecordingRoleManagementService : IRoleManagementService
    {
        public bool WasCalled { get; private set; }

        public IReadOnlyList<string>? LastRoles { get; private set; }

        private ErrorOr<RoleAssignmentResponse> Record()
        {
            WasCalled = true;
            return new RoleAssignmentResponse("admin-1", [Role.Admin], false);
        }

        public Task<ErrorOr<RoleAssignmentResponse>> GetRolesAsync(
            string userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(Record());

        public Task<ErrorOr<RoleAssignmentResponse>> AddRoleAsync(
            string userId,
            string role,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(Record());

        public Task<ErrorOr<RoleAssignmentResponse>> ReplaceRolesAsync(
            string userId,
            IReadOnlyList<string> roles,
            CancellationToken cancellationToken = default)
        {
            LastRoles = roles;
            return Task.FromResult(Record());
        }

        public Task<ErrorOr<Success>> RemoveRoleAsync(
            string userId,
            string role,
            CancellationToken cancellationToken = default)
        {
            WasCalled = true;
            return Task.FromResult<ErrorOr<Success>>(Result.Success);
        }

        public Task<ErrorOr<RoleAssignmentResponse>> SetSuspendedAsync(
            string userId,
            bool isSuspended,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(Record());
    }

    private sealed class StubUserQuery(
        RegisteredUserResponse? user,
        IReadOnlyList<RegisteredUserResponse> users) : IUserQuery
    {
        public Task<IReadOnlyList<RegisteredUserResponse>> GetAllAsync(
            CancellationToken cancellationToken = default) =>
            Task.FromResult(users);

        public Task<RegisteredUserResponse?> GetByIdAsync(
            string userId,
            CancellationToken cancellationToken = default) =>
            Task.FromResult(user);
    }
}
