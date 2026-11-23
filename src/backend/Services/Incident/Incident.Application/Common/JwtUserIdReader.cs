using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;

namespace Incident.Application.Common;

public static class JwtUserIdReader
{
    public static Guid? GetUserIdToken(string? authorizationHeader)
    {
        if (string.IsNullOrWhiteSpace(authorizationHeader))
            return null;
        const string prefix = "Bearer ";
        if (!authorizationHeader.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            return null;

        var token = authorizationHeader[prefix.Length..].Trim();

        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(token))
            return null;

        try
        {

            var jwt = handler.ReadJwtToken(token);

            var sub = jwt.Claims.FirstOrDefault(c =>
                c.Type == JwtRegisteredClaimNames.Sub ||
                c.Type == "nameid" ||
                c.Type == System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            return Guid.TryParse(sub, out var userId) ? userId : null;
        }
        catch
        {
            return null;
        }
    }
    public static string? GetUserRoleToken(string? authorizationHeader)
    {
        if (string.IsNullOrWhiteSpace(authorizationHeader)) return null;

        const string prefix = "Bearer ";
        if (!authorizationHeader.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) return null;

        var token = authorizationHeader[prefix.Length..].Trim();
        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(token)) return null;

        try
        {
            var jwt = handler.ReadJwtToken(token);

            var role = jwt.Claims.FirstOrDefault(c =>
                c.Type == "role" ||
                c.Type == System.Security.Claims.ClaimTypes.Role)?.Value;

            return role;
        }
        catch
        {
            return null;
        }
    }
}
