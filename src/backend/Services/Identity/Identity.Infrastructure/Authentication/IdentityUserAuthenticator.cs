using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Identity.Infrastructure.Authentication;

public sealed class IdentityUserAuthenticator(UserManager<User> userManager) : IUserAuthenticator
{
    public async Task<LoginResult?> AuthenticateAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password)) return null;

        var user = await userManager.FindByEmailAsync(email);

        if (user is null || user.IsSuspended || !await userManager.CheckPasswordAsync(user, password)) return null;

        return new LoginResult(user.Id, user.Email ?? email);
    }
}