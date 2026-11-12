using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Campus.IntegrationTests.Fixtures;

public static class TestJwtGenerator
{
    public const string SecretKey = "7d82f3a9b4e1c60d5f27a8b9c0d1e2f3a4b5c6d7e8f90a1b2c3d4e5f6a7b8c9d";
    public const string Issuer = "https://identity-api";
    public const string Audience = "api-gateway";

    public static string GenerateToken(string? role = "Admin", string userId = "test-user-id", string email = "admin@uct.cl")
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId),
            new(JwtRegisteredClaimNames.Email, email),
            new(ClaimTypes.NameIdentifier, userId),
            new(ClaimTypes.Email, email)
        };

        if (!string.IsNullOrEmpty(role))
        {
            claims.Add(new Claim("role", role));
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var signingCredentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(SecretKey)),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: Issuer,
            audience: Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(2),
            signingCredentials: signingCredentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
