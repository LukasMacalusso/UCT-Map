using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Genera JWT de prueba con el claim <c>sub</c> y, opcionalmente, el claim
/// <c>role</c> que leen los endpoints DELETE de Incident.
/// </summary>
public static class TestJwtWithRole
{
    private static readonly SymmetricSecurityKey Key =
        new(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));

    public static string Create(Guid userId, string? role = null)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString())
        };

        if (role is not null)
            claims.Add(new Claim("role", role));

        var token = new JwtSecurityToken(
            claims: claims,
            signingCredentials: new SigningCredentials(Key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
