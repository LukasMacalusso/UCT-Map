using System.Security.Claims;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Identity.UnitTests;

internal static class TestUserContext
{
    public const string AdminId = "admin-1";

    public static ControllerContext Admin(string userId = AdminId) => For(userId, Role.Admin);

    public static ControllerContext For(string userId, params string[] roles)
    {
        var claims = new List<Claim> { new("sub", userId) };
        claims.AddRange(roles.Select(role => new Claim("role", role)));

        var identity = new ClaimsIdentity(claims, "Test", "sub", "role");
        return new ControllerContext
        {
            HttpContext = new DefaultHttpContext { User = new ClaimsPrincipal(identity) }
        };
    }
}
