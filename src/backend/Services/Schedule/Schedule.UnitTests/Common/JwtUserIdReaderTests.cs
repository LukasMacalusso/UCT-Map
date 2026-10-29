using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Schedule.Application.Common;

namespace Schedule.UnitTests.Common;

public class JwtUserIdReaderTests
{
    [Fact]
    public void GetUserId_WithSubClaim_ReturnsTheUserId()
    {
        var userId = Guid.NewGuid();

        var result = JwtUserIdReader.GetUserId($"Bearer {CreateToken(JwtRegisteredClaimNames.Sub, userId.ToString())}");

        Assert.Equal(userId, result);
    }

    [Fact]
    public void GetUserId_WithNameIdentifierClaim_ReturnsTheUserId()
    {
        var userId = Guid.NewGuid();

        var result = JwtUserIdReader.GetUserId($"Bearer {CreateToken(ClaimTypes.NameIdentifier, userId.ToString())}");

        Assert.Equal(userId, result);
    }

    [Fact]
    public void GetUserId_WhenUserIdIsNotAGuid_ReturnsNull()
    {
        var result = JwtUserIdReader.GetUserId($"Bearer {CreateToken(JwtRegisteredClaimNames.Sub, "not-a-guid")}");

        Assert.Null(result);
    }

    [Fact]
    public void GetUserId_WithoutUserIdClaim_ReturnsNull()
    {
        var result = JwtUserIdReader.GetUserId($"Bearer {CreateToken(JwtRegisteredClaimNames.Email, "student@uct.cl")}");

        Assert.Null(result);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("Bearer not-a-token")]
    [InlineData("Basic dXNlcjpwYXNz")]
    public void GetUserId_WithInvalidHeader_ReturnsNull(string? header)
    {
        Assert.Null(JwtUserIdReader.GetUserId(header));
    }

    private static string CreateToken(string claimType, string value)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes("test-signing-key-0123456789abcdef"));
        var token = new JwtSecurityToken(
            claims: [new Claim(claimType, value)],
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
