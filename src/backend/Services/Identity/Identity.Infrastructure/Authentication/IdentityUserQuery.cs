using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Identity.Infrastructure.Authentication;

public sealed class IdentityUserQuery(UserManager<User> userManager) : IUserQuery
{
    public async Task<IReadOnlyList<RegisteredUserResponse>> GetAllAsync(
        CancellationToken cancellationToken = default)
    {
        var users = await userManager.Users
            .ToListAsync(cancellationToken);
        var responses = new List<RegisteredUserResponse>(users.Count);

        foreach (var user in users)
        {
            var roles = await userManager.GetRolesAsync(user);
            responses.Add(new RegisteredUserResponse(
                user.Id,
                user.Name,
                user.Email ?? string.Empty,
                roles.FirstOrDefault(),
                user.IsSuspended));
        }

        return responses;
    }

    public async Task<RegisteredUserResponse?> GetByIdAsync(
        string userId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(userId)) return null;

        var user = await userManager.FindByIdAsync(userId);
        if (user is null) return null;

        var roles = await userManager.GetRolesAsync(user);

        return new RegisteredUserResponse(
            user.Id,
            user.Name,
            user.Email ?? string.Empty,
            roles.FirstOrDefault(),
            user.IsSuspended);
    }
}
