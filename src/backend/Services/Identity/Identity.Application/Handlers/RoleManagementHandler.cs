using ErrorOr;
using Identity.Application.DTOs;
using Identity.Application.Interfaces;

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

    public Task<ErrorOr<RoleAssignmentResponse>> ExecuteReplaceAsync(
        string userId,
        IReadOnlyList<string> roles,
        CancellationToken cancellationToken = default) =>
        roleManagementService.ReplaceRolesAsync(userId, roles, cancellationToken);

    public Task<ErrorOr<Success>> ExecuteRemoveAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default) =>
        roleManagementService.RemoveRoleAsync(userId, role, cancellationToken);

    public Task<ErrorOr<RoleAssignmentResponse>> ExecuteSetSuspendedAsync(
        string userId,
        bool isSuspended,
        CancellationToken cancellationToken = default) =>
        roleManagementService.SetSuspendedAsync(userId, isSuspended, cancellationToken);
}
