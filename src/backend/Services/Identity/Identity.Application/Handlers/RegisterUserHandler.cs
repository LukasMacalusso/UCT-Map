using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using ErrorOr;
using System.Threading;
using System.Threading.Tasks;

namespace Identity.Application.Handlers;

public sealed class RegisterUserHandler(IUserRegistrationService registrationService)
{
    public async Task<ErrorOr<RegisteredUserResponse>> ExecuteAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password)) return Error.Validation(code: "Identity.Register.InvalidRequest", description: "Name, email, and password are required.");
        var createdUser = await registrationService.RegisterAsync(request, cancellationToken);
        if (createdUser is null) return Error.Failure(code: "Identity.Register.Failed", description: "Unable to register the user.");
        return createdUser;
    }
}
