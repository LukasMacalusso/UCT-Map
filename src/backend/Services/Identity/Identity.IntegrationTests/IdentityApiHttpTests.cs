using System.Net;
using System.Net.Http.Json;
using Identity.Application.DTOs;
using Identity.Domain.Entities;
using Identity.IntegrationTests.Fixtures;

namespace Identity.IntegrationTests;

public sealed class IdentityApiHttpTests : IDisposable
{
    private const string AdminEmail = "admin@uct.cl";
    private const string StudentEmail = "student@uct.cl";

    private readonly IdentityApiFactory _factory = new();

    public void Dispose() => _factory.Dispose();

    [Fact]
    public async Task Health_ReturnsOk()
    {
        var response = await _factory.CreateClient().GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task HealthDatabase_WhenDatabaseIsReachable_ReturnsOk()
    {
        var response = await _factory.CreateClient().GetAsync("/health/database");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithValidData_ReturnsCreatedStudent()
    {
        var response = await _factory.CreateClient().PostAsJsonAsync(
            "/api/identity/register",
            new RegisterRequest("Ana Torres", "ana@uct.cl", IdentityApiFactory.Password));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var user = await response.Content.ReadFromJsonAsync<RegisteredUserResponse>();
        Assert.Equal(Role.Student, user?.Role);
    }

    [Fact]
    public async Task Register_WithPrivilegedRole_ReturnsBadRequest()
    {
        var response = await _factory.CreateClient().PostAsJsonAsync(
            "/api/identity/register",
            new RegisterRequest("Ana Torres", "ana@uct.cl", IdentityApiFactory.Password, Role.Admin));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Register_WithDuplicatedEmail_ReturnsBadRequest()
    {
        await _factory.CreateUserAsync(StudentEmail, Role.Student);

        var response = await _factory.CreateClient().PostAsJsonAsync(
            "/api/identity/register",
            new RegisterRequest("Other User", StudentEmail, IdentityApiFactory.Password));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Login_WithInvalidPassword_ReturnsUnauthorized()
    {
        await _factory.CreateUserAsync(StudentEmail, Role.Student);

        var response = await _factory.CreateClient().PostAsJsonAsync(
            "/api/identity/login",
            new LoginRequest(StudentEmail, "WrongPassword123!"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetAll_WithoutToken_ReturnsUnauthorized()
    {
        var response = await _factory.CreateClient().GetAsync("/api/identity");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetById_WithStudentToken_ReturnsOwnProfileOnly()
    {
        var userId = await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var otherUserId = await _factory.CreateUserAsync("other@uct.cl", Role.Student);
        var client = await _factory.CreateAuthenticatedClientAsync(StudentEmail);

        var own = await client.GetAsync($"/api/identity/{userId}");
        var other = await client.GetAsync($"/api/identity/{otherUserId}");
        var missing = await client.GetAsync("/api/identity/missing-user");
        var all = await client.GetFromJsonAsync<List<RegisteredUserResponse>>("/api/identity");

        Assert.Equal(HttpStatusCode.OK, own.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, other.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, missing.StatusCode);
        Assert.Contains(all ?? [], user => user.UserId == userId);
    }

    [Fact]
    public async Task GetById_WithAdminToken_ReturnsUserOrNotFound()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        var userId = await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var client = await _factory.CreateAuthenticatedClientAsync(AdminEmail);

        var found = await client.GetAsync($"/api/identity/{userId}");
        var missing = await client.GetAsync("/api/identity/missing-user");

        Assert.Equal(HttpStatusCode.OK, found.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
    }

    [Fact]
    public async Task GetAll_HidesSuspendedUsersFromNonAdmins()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var suspendedId = await _factory.CreateUserAsync("suspended@uct.cl", Role.Student);
        var admin = await _factory.CreateAuthenticatedClientAsync(AdminEmail);
        var student = await _factory.CreateAuthenticatedClientAsync(StudentEmail);
        await admin.PostAsync($"/api/identity/{suspendedId}/suspension", null);

        var adminUsers = await admin.GetFromJsonAsync<List<RegisteredUserResponse>>("/api/identity");
        var studentUsers = await student.GetFromJsonAsync<List<RegisteredUserResponse>>("/api/identity");

        Assert.Contains(adminUsers ?? [], user => user.UserId == suspendedId);
        Assert.DoesNotContain(studentUsers ?? [], user => user.UserId == suspendedId);
    }

    [Fact]
    public async Task AdminProtection_BlocksSelfSuspensionAndSelfDemotion()
    {
        var adminId = await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        var client = await _factory.CreateAuthenticatedClientAsync(AdminEmail);

        var suspend = await client.PostAsync($"/api/identity/{adminId}/suspension", null);
        var remove = await client.DeleteAsync($"/api/identity/{adminId}/roles/{Role.Admin}");
        var replace = await client.PutAsJsonAsync(
            $"/api/identity/{adminId}/roles",
            new RoleReplacementRequest([Role.Teacher]));

        Assert.Equal(HttpStatusCode.Forbidden, suspend.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, remove.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, replace.StatusCode);
    }

    [Fact]
    public async Task AdminProtection_RejectsTokenOfSuspendedAdmin()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        const string otherAdminEmail = "other-admin@uct.cl";
        var otherAdminId = await _factory.CreateUserAsync(otherAdminEmail, Role.Admin);
        var admin = await _factory.CreateAuthenticatedClientAsync(AdminEmail);
        var otherAdmin = await _factory.CreateAuthenticatedClientAsync(otherAdminEmail);

        var suspend = await admin.PostAsync($"/api/identity/{otherAdminId}/suspension", null);
        var selfReactivate = await otherAdmin.DeleteAsync($"/api/identity/{otherAdminId}/suspension");
        var list = await otherAdmin.GetAsync("/api/identity");

        Assert.Equal(HttpStatusCode.OK, suspend.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, selfReactivate.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, list.StatusCode);
    }

    [Fact]
    public async Task AdminProtection_UsesCurrentRolesInsteadOfTokenRoles()
    {
        var adminId = await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        const string otherAdminEmail = "other-admin@uct.cl";
        var otherAdminId = await _factory.CreateUserAsync(otherAdminEmail, Role.Admin);
        var admin = await _factory.CreateAuthenticatedClientAsync(AdminEmail);
        var demotedAdmin = await _factory.CreateAuthenticatedClientAsync(otherAdminEmail);

        var demote = await admin.PutAsJsonAsync(
            $"/api/identity/{otherAdminId}/roles",
            new RoleReplacementRequest([Role.Teacher]));
        var staleAdminAction = await demotedAdmin.PostAsync($"/api/identity/{adminId}/suspension", null);

        Assert.Equal(HttpStatusCode.OK, demote.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, staleAdminAction.StatusCode);
    }

    [Fact]
    public async Task ReplaceRoles_WithEmptyList_ReturnsBadRequest()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        var userId = await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var client = await _factory.CreateAuthenticatedClientAsync(AdminEmail);

        var response = await client.PutAsJsonAsync(
            $"/api/identity/{userId}/roles",
            new RoleReplacementRequest([]));

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task AdminProtection_AllowsManagingAnotherAdminWhenOneStaysActive()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        var otherAdminId = await _factory.CreateUserAsync("other-admin@uct.cl", Role.Admin);
        var client = await _factory.CreateAuthenticatedClientAsync(AdminEmail);

        var remove = await client.DeleteAsync($"/api/identity/{otherAdminId}/roles/{Role.Admin}");
        var suspend = await client.PostAsync($"/api/identity/{otherAdminId}/suspension", null);

        Assert.Equal(HttpStatusCode.NoContent, remove.StatusCode);
        Assert.Equal(HttpStatusCode.OK, suspend.StatusCode);
    }

    [Fact]
    public async Task RoleManagement_WithStudentToken_ReturnsForbidden()
    {
        var userId = await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var client = await _factory.CreateAuthenticatedClientAsync(StudentEmail);

        var response = await client.GetAsync($"/api/identity/{userId}/roles");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task RoleManagement_WithAdminToken_ManagesRolesAndSuspension()
    {
        await _factory.CreateUserAsync(AdminEmail, Role.Admin);
        var userId = await _factory.CreateUserAsync(StudentEmail, Role.Student);
        var client = await _factory.CreateAuthenticatedClientAsync(AdminEmail);
        var rolesUrl = $"/api/identity/{userId}/roles";

        var getRoles = await client.GetAsync(rolesUrl);
        Assert.Equal(HttpStatusCode.OK, getRoles.StatusCode);

        var addRole = await client.PostAsJsonAsync(rolesUrl, new RoleAssignmentRequest(Role.Teacher));
        Assert.Equal(HttpStatusCode.Created, addRole.StatusCode);

        var addDuplicated = await client.PostAsJsonAsync(rolesUrl, new RoleAssignmentRequest(Role.Teacher));
        Assert.Equal(HttpStatusCode.Conflict, addDuplicated.StatusCode);

        var addUnknown = await client.PostAsJsonAsync(rolesUrl, new RoleAssignmentRequest("Unknown"));
        Assert.Equal(HttpStatusCode.NotFound, addUnknown.StatusCode);

        var addEmpty = await client.PostAsJsonAsync(rolesUrl, new RoleAssignmentRequest(" "));
        Assert.Equal(HttpStatusCode.BadRequest, addEmpty.StatusCode);

        var replace = await client.PutAsJsonAsync(
            rolesUrl,
            new RoleReplacementRequest([Role.ObjectsOfficer, Role.Teacher]));
        var replaced = await replace.Content.ReadFromJsonAsync<RoleAssignmentResponse>();
        Assert.Equal(HttpStatusCode.OK, replace.StatusCode);
        Assert.Equal(
            new[] { Role.ObjectsOfficer, Role.Teacher }.Order(),
            (replaced?.Roles ?? []).Order());

        var replaceUnknown = await client.PutAsJsonAsync(rolesUrl, new RoleReplacementRequest(["Unknown"]));
        Assert.Equal(HttpStatusCode.NotFound, replaceUnknown.StatusCode);

        var remove = await client.DeleteAsync($"{rolesUrl}/{Role.Teacher}");
        Assert.Equal(HttpStatusCode.NoContent, remove.StatusCode);

        var removeMissing = await client.DeleteAsync($"{rolesUrl}/{Role.Teacher}");
        Assert.Equal(HttpStatusCode.NotFound, removeMissing.StatusCode);

        var suspend = await client.PostAsync($"/api/identity/{userId}/suspension", null);
        Assert.Equal(HttpStatusCode.OK, suspend.StatusCode);

        var suspendedLogin = await _factory.CreateClient().PostAsJsonAsync(
            "/api/identity/login",
            new LoginRequest(StudentEmail, IdentityApiFactory.Password));
        Assert.Equal(HttpStatusCode.Unauthorized, suspendedLogin.StatusCode);

        var reactivate = await client.DeleteAsync($"/api/identity/{userId}/suspension");
        Assert.Equal(HttpStatusCode.OK, reactivate.StatusCode);

        var missingUser = await client.GetAsync("/api/identity/missing-user/roles");
        Assert.Equal(HttpStatusCode.NotFound, missingUser.StatusCode);
    }
}
