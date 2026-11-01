using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;

namespace Schedule.Application.Common;

// The API Gateway validates the token signature; this only reads the user id from it.
public static class JwtUserIdReader
{
    private const string BearerPrefix = "Bearer ";

    public static Guid? GetUserId(string? authorizationHeader)
    {
        if (string.IsNullOrWhiteSpace(authorizationHeader)) return null;
        if (!authorizationHeader.StartsWith(BearerPrefix, StringComparison.OrdinalIgnoreCase)) return null;

        var token = authorizationHeader[BearerPrefix.Length..].Trim();
        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(token)) return null;

        try
        {
            var userId = handler.ReadJwtToken(token).Claims.FirstOrDefault(c =>
                c.Type == JwtRegisteredClaimNames.Sub ||
                c.Type == "nameid" ||
                c.Type == ClaimTypes.NameIdentifier)?.Value;

            return Guid.TryParse(userId, out var id) ? id : null;
        }
        catch (ArgumentException)
        {
            return null;
        }
    }
}
