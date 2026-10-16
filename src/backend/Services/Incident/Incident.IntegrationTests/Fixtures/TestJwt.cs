using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Genera JWT de prueba con el claim <c>sub</c> (el id real del usuario),
/// igual que lo hace Identity. La API de Incident no valida la firma, solo
/// lee el claim, así que cualquier clave sirve para los tests end-to-end.
/// </summary>
public static class TestJwt
{
    private static readonly SymmetricSecurityKey Key =
        new(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));

    public static string Create(Guid userId)
    {
        var token = new JwtSecurityToken(
            claims: new[] { new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()) },
            signingCredentials: new SigningCredentials(Key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
