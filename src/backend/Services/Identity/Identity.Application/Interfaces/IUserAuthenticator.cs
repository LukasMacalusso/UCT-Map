using Identity.Application.DTOs;
namespace Identity.Application.Interfaces;

public interface IUserAuthenticator
{
    Task<LoginResult?> AuthenticateAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default);
}