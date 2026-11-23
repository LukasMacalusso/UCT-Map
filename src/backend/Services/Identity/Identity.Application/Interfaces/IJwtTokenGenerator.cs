using Identity.Application.DTOs;
namespace Identity.Application.Interfaces;

public interface IJwtTokenGenerator
{
    Task<string> GenerateAsync(LoginResult user, CancellationToken cancellationToken = default);
}