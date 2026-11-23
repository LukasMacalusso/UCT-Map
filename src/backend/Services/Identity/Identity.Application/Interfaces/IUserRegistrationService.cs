using Identity.Application.DTOs;
namespace Identity.Application.Interfaces;

public interface IUserRegistrationService
{
    Task<RegisteredUserResponse?> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default);
}

