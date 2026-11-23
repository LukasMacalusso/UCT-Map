using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using ErrorOr;
using System.Threading;
using System.Threading.Tasks;

namespace Identity.Application.Handlers;

public sealed class LoginHandler(IUserAuthenticator userAuthenticator, IJwtTokenGenerator jwtTokenGenerator)
{
    public async Task<ErrorOr<LoginResult>> ExecuteAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var userResult = await userAuthenticator.AuthenticateAsync(request.Email, request.Password, cancellationToken);
        if (userResult is null) return Error.Unauthorized(code: "Auth.InvalidCredentials", description: "Invalid email or password.");
        var token = await jwtTokenGenerator.GenerateAsync(userResult, cancellationToken);
        return userResult with { Token = token };
    }
}
