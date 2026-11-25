using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Campus.IntegrationTests.Fixtures;

public static class TestJwtGenerator
{
    public const string SecretKey = "campus-tests-signing-key-0123456789abcdef";
    public const string InvalidSecretKey = "wrong-tests-signing-key-fedcba9876543210";
    public const string Issuer = "https://identity-api";
    public const string Audience = "api-gateway";

    public static string GenerateToken(string? role = "Admin", string userId = "test-user-id", string email = "admin@uct.cl") =>
        GenerateCustomToken(role: role, userId: userId, email: email);

    public static string GenerateExpiredToken(string? role = "Admin") =>
        GenerateCustomToken(
            role: role,
            notBefore: DateTime.UtcNow.AddHours(-2),
            expires: DateTime.UtcNow.AddMinutes(-10));

    public static string GenerateTokenWithInvalidKey(string? role = "Admin") =>
        GenerateCustomToken(role: role, secretKey: InvalidSecretKey);

    public static string GenerateTokenWithInvalidIssuer(string? role = "Admin") =>
        GenerateCustomToken(role: role, issuer: "https://untrusted-issuer");

    public static string GenerateTokenWithInvalidAudience(string? role = "Admin") =>
        GenerateCustomToken(role: role, audience: "invalid-audience");

    public static string GenerateCustomToken(
        string? role = "Admin",
        string? secretKey = null,
        string? issuer = null,
        string? audience = null,
        DateTime? notBefore = null,
        DateTime? expires = null,
        string userId = "test-user-id",
        string email = "admin@uct.cl")
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
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey ?? SecretKey)),
            SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer ?? Issuer,
            audience: audience ?? Audience,
            claims: claims,
            notBefore: notBefore ?? DateTime.UtcNow.AddMinutes(-1),
            expires: expires ?? DateTime.UtcNow.AddHours(2),
            signingCredentials: signingCredentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
