using Identity.Application.DTOs;
namespace Identity.Application.Interfaces;

public interface IUserQuery
{
    Task<IReadOnlyList<RegisteredUserResponse>> GetAllAsync(
        CancellationToken cancellationToken = default);

    Task<RegisteredUserResponse?> GetByIdAsync(
        string userId,
        CancellationToken cancellationToken = default);
}
