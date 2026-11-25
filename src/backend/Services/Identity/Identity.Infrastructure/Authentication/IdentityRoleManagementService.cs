using ErrorOr;
using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Identity.Infrastructure.Authentication;

public sealed class IdentityRoleManagementService(
    UserManager<User> userManager,
    RoleManager<Role> roleManager) : IRoleManagementService
{
    public async Task<ErrorOr<RoleAssignmentResponse>> GetRolesAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        var user = await FindUserAsync(userId);
        if (user is null)
        {
            return Error.NotFound(
                code: "Identity.User.NotFound",
                description: "User was not found.");
        }

        return await CreateResponseAsync(user);
    }

    public async Task<ErrorOr<RoleAssignmentResponse>> AddRoleAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default)
    {
        var user = await FindUserAsync(userId);
        if (user is null)
        {
            return Error.NotFound(
                code: "Identity.User.NotFound",
                description: "User was not found.");
        }

        var normalizedRole = role.Trim();
        if (string.IsNullOrWhiteSpace(normalizedRole))
        {
            return Error.Validation(
                code: "Identity.Role.Required",
                description: "Role is required.");
        }

        if (!await roleManager.RoleExistsAsync(normalizedRole))
        {
            return Error.NotFound(
                code: "Identity.Role.NotFound",
                description: "Role was not found.");
        }

        if (await userManager.IsInRoleAsync(user, normalizedRole))
        {
            return Error.Conflict(
                code: "Identity.Role.AlreadyAssigned",
                description: "Role is already assigned to the user.");
        }

        var result = await userManager.AddToRoleAsync(user, normalizedRole);
        if (!result.Succeeded)
        {
            return Error.Failure(
                code: "Identity.Role.AssignFailed",
                description: "The role could not be assigned.");
        }

        return await CreateResponseAsync(user);
    }

    public async Task<ErrorOr<RoleAssignmentResponse>> ReplaceRolesAsync(
        string userId,
        IReadOnlyList<string> roles,
        CancellationToken cancellationToken = default)
    {
        var user = await FindUserAsync(userId);
        if (user is null)
        {
            return Error.NotFound(
                code: "Identity.User.NotFound",
                description: "User was not found.");
        }

        var normalizedRoles = roles
            .Where(role => !string.IsNullOrWhiteSpace(role))
            .Select(role => role.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        if (normalizedRoles.Length == 0)
        {
            return Error.Validation(
                code: "Identity.Role.Required",
                description: "At least one role is required.");
        }

        foreach (var role in normalizedRoles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                return Error.NotFound(
                    code: "Identity.Role.NotFound",
                    description: $"Role '{role}' was not found.");
            }
        }

        var currentRoles = await userManager.GetRolesAsync(user);
        var rolesToRemove = currentRoles.Except(normalizedRoles, StringComparer.OrdinalIgnoreCase).ToArray();
        var rolesToAdd = normalizedRoles.Except(currentRoles, StringComparer.OrdinalIgnoreCase).ToArray();

        if (rolesToRemove.Any(IsAdminRole) && await IsLastActiveAdminAsync(user))
        {
            return LastActiveAdmin();
        }

        if (rolesToRemove.Length > 0)
        {
            var removeResult = await userManager.RemoveFromRolesAsync(user, rolesToRemove);
            if (!removeResult.Succeeded)
            {
                return Error.Failure(
                    code: "Identity.Role.ReplaceFailed",
                    description: "The user roles could not be replaced.");
            }
        }

        if (rolesToAdd.Length > 0)
        {
            var addResult = await userManager.AddToRolesAsync(user, rolesToAdd);
            if (!addResult.Succeeded)
            {
                return Error.Failure(
                    code: "Identity.Role.ReplaceFailed",
                    description: "The user roles could not be replaced.");
            }
        }

        return await CreateResponseAsync(user);
    }

    public async Task<ErrorOr<Success>> RemoveRoleAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default)
    {
        var user = await FindUserAsync(userId);
        if (user is null)
        {
            return Error.NotFound(
                code: "Identity.User.NotFound",
                description: "User was not found.");
        }

        if (!await userManager.IsInRoleAsync(user, role))
        {
            return Error.NotFound(
                code: "Identity.Role.NotAssigned",
                description: "Role is not assigned to the user.");
        }

        if (IsAdminRole(role) && await IsLastActiveAdminAsync(user))
        {
            return LastActiveAdmin();
        }

        var result = await userManager.RemoveFromRoleAsync(user, role);
        return result.Succeeded
            ? Result.Success
            : Error.Failure(
                code: "Identity.Role.RemoveFailed",
                description: "The role could not be removed.");
    }

    public async Task<ErrorOr<RoleAssignmentResponse>> SetSuspendedAsync(
        string userId,
        bool isSuspended,
        CancellationToken cancellationToken = default)
    {
        var user = await FindUserAsync(userId);
        if (user is null)
        {
            return Error.NotFound(
                code: "Identity.User.NotFound",
                description: "User was not found.");
        }

        if (isSuspended && await IsLastActiveAdminAsync(user))
        {
            return LastActiveAdmin();
        }

        user.SetSuspended(isSuspended);
        var result = await userManager.UpdateAsync(user);
        if (!result.Succeeded)
        {
            return Error.Failure(
                code: "Identity.User.StatusUpdateFailed",
                description: "The user status could not be updated.");
        }

        return await CreateResponseAsync(user);
    }

    private Task<User?> FindUserAsync(string userId) =>
        string.IsNullOrWhiteSpace(userId)
            ? Task.FromResult<User?>(null)
            : userManager.FindByIdAsync(userId);

    private async Task<bool> IsLastActiveAdminAsync(User user)
    {
        if (user.IsSuspended || !await userManager.IsInRoleAsync(user, Role.Admin)) return false;

        var admins = await userManager.GetUsersInRoleAsync(Role.Admin);
        return !admins.Any(admin => admin.Id != user.Id && !admin.IsSuspended);
    }

    private static bool IsAdminRole(string role) =>
        string.Equals(role.Trim(), Role.Admin, StringComparison.OrdinalIgnoreCase);

    private static Error LastActiveAdmin() =>
        Error.Conflict(
            code: "Identity.Admin.LastActiveAdmin",
            description: "The system must keep at least one active administrator.");

    private async Task<RoleAssignmentResponse> CreateResponseAsync(User user) =>
        new(user.Id, (await userManager.GetRolesAsync(user)).ToArray(), user.IsSuspended);
}
