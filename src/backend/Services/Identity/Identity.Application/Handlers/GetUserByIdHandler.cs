using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using ErrorOr;
using System.Threading;
using System.Threading.Tasks;

namespace Identity.Application.Handlers;

public sealed class GetUserByIdHandler(IUserQuery userQuery)
{
    public async Task<IReadOnlyList<RegisteredUserResponse>> ExecuteAllAsync(
        bool requesterIsAdmin,
        CancellationToken cancellationToken = default)
    {
        var users = await userQuery.GetAllAsync(cancellationToken);
        return requesterIsAdmin
            ? users
            : users.Where(user => !user.IsSuspended).ToArray();
    }

    public async Task<ErrorOr<RegisteredUserResponse>> ExecuteAsync(
        string userId,
        string? requesterId,
        bool requesterIsAdmin,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId)) return Error.Validation(code: "Identity.GetUser.InvalidRequest", description: "User id is required.");

        if (!requesterIsAdmin && !string.Equals(requesterId, userId, StringComparison.Ordinal))
        {
            return Error.Forbidden(code: "Identity.GetUser.Forbidden", description: "Only administrators can view other users' profiles.");
        }

        var user = await userQuery.GetByIdAsync(userId, cancellationToken);
        if (user is null) return Error.NotFound(code: "Identity.GetUser.NotFound", description: "User was not found.");
        return user;
    }
}
