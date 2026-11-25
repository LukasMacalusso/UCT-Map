using ErrorOr;
using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;

namespace Identity.Application.Handlers;

public sealed class RoleManagementHandler(IRoleManagementService roleManagementService)
{
    public Task<ErrorOr<RoleAssignmentResponse>> ExecuteGetAsync(
        string userId,
        CancellationToken cancellationToken = default) =>
        roleManagementService.GetRolesAsync(userId, cancellationToken);

    public Task<ErrorOr<RoleAssignmentResponse>> ExecuteAddAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default) =>
        roleManagementService.AddRoleAsync(userId, role, cancellationToken);

    public async Task<ErrorOr<RoleAssignmentResponse>> ExecuteReplaceAsync(
        string actingUserId,
        string userId,
        IReadOnlyList<string> roles,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(actingUserId)) return MissingActingUser();

        var requestedRoles = roles ?? [];
        var keepsAdminRole = requestedRoles.Any(role => role is not null && IsAdminRole(role.Trim()));
        if (IsSameUser(actingUserId, userId) && !keepsAdminRole) return SelfDemotion();

        return await roleManagementService.ReplaceRolesAsync(userId, requestedRoles, cancellationToken);
    }

    public async Task<ErrorOr<Success>> ExecuteRemoveAsync(
        string actingUserId,
        string userId,
        string role,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(actingUserId)) return MissingActingUser();
        if (IsSameUser(actingUserId, userId) && IsAdminRole(role)) return SelfDemotion();

        return await roleManagementService.RemoveRoleAsync(userId, role, cancellationToken);
    }

    public async Task<ErrorOr<RoleAssignmentResponse>> ExecuteSetSuspendedAsync(
        string actingUserId,
        string userId,
        bool isSuspended,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(actingUserId)) return MissingActingUser();

        if (isSuspended && IsSameUser(actingUserId, userId))
        {
            return Error.Forbidden(
                code: "Identity.Admin.SelfSuspension",
                description: "Administrators cannot suspend their own account.");
        }

        return await roleManagementService.SetSuspendedAsync(userId, isSuspended, cancellationToken);
    }

    private static bool IsSameUser(string actingUserId, string userId) =>
        string.Equals(actingUserId, userId, StringComparison.Ordinal);

    private static bool IsAdminRole(string role) =>
        string.Equals(role, Role.Admin, StringComparison.OrdinalIgnoreCase);

    private static Error MissingActingUser() =>
        Error.Unauthorized(
            code: "Identity.Admin.MissingActingUser",
            description: "The acting user could not be identified.");

    private static Error SelfDemotion() =>
        Error.Forbidden(
            code: "Identity.Admin.SelfDemotion",
            description: "Administrators cannot remove their own Admin role.");
}
