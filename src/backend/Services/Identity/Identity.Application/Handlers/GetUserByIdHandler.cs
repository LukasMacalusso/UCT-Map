using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using ErrorOr;
using System.Threading;
using System.Threading.Tasks;

namespace Identity.Application.Handlers;

public sealed class GetUserByIdHandler(IUserQuery userQuery)
{
    public Task<IReadOnlyList<RegisteredUserResponse>> ExecuteAllAsync(
        CancellationToken cancellationToken = default) =>
        userQuery.GetAllAsync(cancellationToken);

    public async Task<ErrorOr<RegisteredUserResponse>> ExecuteAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId)) return Error.Validation(code: "Identity.GetUser.InvalidRequest", description: "User id is required.");
        var user = await userQuery.GetByIdAsync(userId, cancellationToken);
        if (user is null) return Error.NotFound(code: "Identity.GetUser.NotFound", description: "User was not found.");
        return user;
    }
}
