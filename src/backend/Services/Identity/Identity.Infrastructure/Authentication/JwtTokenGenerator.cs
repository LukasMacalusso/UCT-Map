using Identity.Application.DTOs;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Identity.Application.Interfaces;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace Identity.Infrastructure.Authentication;

public sealed class JwtTokenGenerator(UserManager<User> userManager, IOptions<JwtSettings> options) : IJwtTokenGenerator
{
    private const string RoleClaimType = "role";

    public async Task<string> GenerateAsync(LoginResult user, CancellationToken cancellationToken = default)
    {
        var settings = options.Value;
        var identityUser = await userManager.FindByIdAsync(user.UserId)
            ?? throw new InvalidOperationException("The authenticated user no longer exists.");
        var roles = await userManager.GetRolesAsync(identityUser);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.UserId),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(ClaimTypes.NameIdentifier, user.UserId),
            new(ClaimTypes.Email, user.Email)
        };

        claims.AddRange(roles.SelectMany(role => new[]
        {
            new Claim(RoleClaimType, role),
            new Claim(ClaimTypes.Role, role)
        }));

        var signingCredentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.Key)),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: settings.Issuer,
            audience: settings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(settings.TokenValidationMins),
            signingCredentials: signingCredentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
