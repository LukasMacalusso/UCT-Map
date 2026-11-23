using ErrorOr;
using Identity.Application.DTOs;

namespace Identity.Application.Interfaces;

public interface IRoleManagementService
{
    Task<ErrorOr<RoleAssignmentResponse>> GetRolesAsync(
        string userId,
        CancellationToken cancellationToken = default);

    Task<ErrorOr<RoleAssignmentResponse>> AddRoleAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default);

    Task<ErrorOr<RoleAssignmentResponse>> ReplaceRolesAsync(
        string userId,
        IReadOnlyList<string> roles,
        CancellationToken cancellationToken = default);

    Task<ErrorOr<Success>> RemoveRoleAsync(
        string userId,
        string role,
        CancellationToken cancellationToken = default);

    Task<ErrorOr<RoleAssignmentResponse>> SetSuspendedAsync(
        string userId,
        bool isSuspended,
        CancellationToken cancellationToken = default);
}
