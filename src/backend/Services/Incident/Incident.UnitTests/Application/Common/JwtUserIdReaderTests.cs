using Incident.Application.Common;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;
using Microsoft.IdentityModel.Tokens;

namespace Incident.UnitTests.Application.Common;

/// <summary>
/// Cubre la lectura de claims del token que usan los controllers de Incident.
/// La API no valida la firma: solo lee <c>sub</c>/<c>nameid</c> y <c>role</c>.
/// </summary>
public class JwtUserIdReaderTests
{
    private static readonly SymmetricSecurityKey Key =
        new(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));

    private static string CreateToken(params Claim[] claims)
    {
        var token = new JwtSecurityToken(
            claims: claims,
            signingCredentials: new SigningCredentials(Key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string Base64Url(string value) =>
        Convert.ToBase64String(Encoding.UTF8.GetBytes(value))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');

    private static string RawToken(string payloadJson, string headerJson = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}") =>
        $"{Base64Url(headerJson)}.{Base64Url(payloadJson)}.firma";

    // ---------------- GetUserIdToken ----------------

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void GetUserIdToken_SinHeader_RetornaNull(string? authorizationHeader) =>
        Assert.Null(JwtUserIdReader.GetUserIdToken(authorizationHeader));

    [Theory]
    [InlineData("Basic abc")]
    [InlineData("Token abc")]
    [InlineData("Bearer")]
    [InlineData("bearer")]
    public void GetUserIdToken_ConPrefijoInvalido_RetornaNull(string authorizationHeader) =>
        Assert.Null(JwtUserIdReader.GetUserIdToken(authorizationHeader));

    [Fact]
    public void GetUserIdToken_ConTokenIlegible_RetornaNull() =>
        Assert.Null(JwtUserIdReader.GetUserIdToken("Bearer esto-no-es-un-jwt"));

    [Fact]
    public void GetUserIdToken_ConPayloadInvalido_RetornaNull() =>
        Assert.Null(JwtUserIdReader.GetUserIdToken($"Bearer {RawToken("no-es-json")}"));

    [Fact]
    public void GetUserIdToken_ConClaimSubValido_RetornaElGuid()
    {
        var userId = Guid.NewGuid();
        var token = CreateToken(new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()));

        Assert.Equal(userId, JwtUserIdReader.GetUserIdToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserIdToken_ConClaimNameId_RetornaElGuid()
    {
        var userId = Guid.NewGuid();
        var token = CreateToken(new Claim("nameid", userId.ToString()));

        Assert.Equal(userId, JwtUserIdReader.GetUserIdToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserIdToken_ConClaimNameIdentifierUri_RetornaElGuid()
    {
        var userId = Guid.NewGuid();
        var payload = JsonSerializer.Serialize(new Dictionary<string, string>
        {
            [ClaimTypes.NameIdentifier] = userId.ToString()
        });

        Assert.Equal(userId, JwtUserIdReader.GetUserIdToken($"Bearer {RawToken(payload)}"));
    }

    [Fact]
    public void GetUserIdToken_ConSubQueNoEsGuid_RetornaNull()
    {
        var token = CreateToken(new Claim(JwtRegisteredClaimNames.Sub, "no-es-un-guid"));

        Assert.Null(JwtUserIdReader.GetUserIdToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserIdToken_SinClaimsDeUsuario_RetornaNull()
    {
        var token = CreateToken(new Claim("role", "Admin"));

        Assert.Null(JwtUserIdReader.GetUserIdToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserIdToken_ConPrefijoEnMinusculas_EsCaseInsensitive()
    {
        var userId = Guid.NewGuid();
        var token = CreateToken(new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()));

        Assert.Equal(userId, JwtUserIdReader.GetUserIdToken($"bearer {token}"));
    }

    [Fact]
    public void GetUserIdToken_RecortaEspaciosAlrededorDelToken()
    {
        var userId = Guid.NewGuid();
        var token = CreateToken(new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()));

        Assert.Equal(userId, JwtUserIdReader.GetUserIdToken($"Bearer   {token}   "));
    }

    // ---------------- GetUserRoleToken ----------------

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void GetUserRoleToken_SinHeader_RetornaNull(string? authorizationHeader) =>
        Assert.Null(JwtUserIdReader.GetUserRoleToken(authorizationHeader));

    [Theory]
    [InlineData("Basic abc")]
    [InlineData("Token abc")]
    [InlineData("Bearer")]
    public void GetUserRoleToken_ConPrefijoInvalido_RetornaNull(string authorizationHeader) =>
        Assert.Null(JwtUserIdReader.GetUserRoleToken(authorizationHeader));

    [Fact]
    public void GetUserRoleToken_ConTokenIlegible_RetornaNull() =>
        Assert.Null(JwtUserIdReader.GetUserRoleToken("Bearer esto-no-es-un-jwt"));

    [Fact]
    public void GetUserRoleToken_ConPayloadInvalido_RetornaNull() =>
        Assert.Null(JwtUserIdReader.GetUserRoleToken($"Bearer {RawToken("no-es-json")}"));

    [Fact]
    public void GetUserRoleToken_ConClaimRole_RetornaElRol()
    {
        var token = CreateToken(new Claim("role", "ObjectsOfficer"));

        Assert.Equal("ObjectsOfficer", JwtUserIdReader.GetUserRoleToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserRoleToken_ConClaimRoleUri_RetornaElRol()
    {
        var payload = JsonSerializer.Serialize(new Dictionary<string, string>
        {
            [ClaimTypes.Role] = "Admin"
        });

        Assert.Equal("Admin", JwtUserIdReader.GetUserRoleToken($"Bearer {RawToken(payload)}"));
    }

    [Fact]
    public void GetUserRoleToken_SinClaimRole_RetornaNull()
    {
        var token = CreateToken(new Claim(JwtRegisteredClaimNames.Sub, Guid.NewGuid().ToString()));

        Assert.Null(JwtUserIdReader.GetUserRoleToken($"Bearer {token}"));
    }

    [Fact]
    public void GetUserRoleToken_RecortaEspaciosAlrededorDelToken()
    {
        var token = CreateToken(new Claim("role", "ComplaintsOfficer"));

        Assert.Equal("ComplaintsOfficer", JwtUserIdReader.GetUserRoleToken($"Bearer  {token}  "));
    }
}
