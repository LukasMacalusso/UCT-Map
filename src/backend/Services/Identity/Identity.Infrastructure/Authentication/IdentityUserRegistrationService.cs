using Identity.Application.DTOs;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Identity.Infrastructure.Authentication;

public sealed class IdentityUserRegistrationService(
    UserManager<User> userManager,
    RoleManager<Role> roleManager) : IUserRegistrationService
{
    public async Task<RegisteredUserResponse?> RegisterAsync(
        RegisterRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrWhiteSpace(request.Password) ||
            string.IsNullOrWhiteSpace(request.Name)) return null;

        var existingUser = await userManager.FindByEmailAsync(request.Email);
        if (existingUser is not null) return null;

        if (!string.IsNullOrWhiteSpace(request.Role)
            && !string.Equals(request.Role, Role.Student, StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        var user = User.Create(request.Name, request.Email);
        var result = await userManager.CreateAsync(user, request.Password);

        if (!result.Succeeded) return null;

        var roleName = Role.Student;

        if (!string.IsNullOrWhiteSpace(roleName) && await roleManager.RoleExistsAsync(roleName))
        {
            await userManager.AddToRoleAsync(user, roleName);
        }

        return new RegisteredUserResponse(
            user.Id,
            user.Name,
            user.Email ?? request.Email,
            roleName);
    }
}
