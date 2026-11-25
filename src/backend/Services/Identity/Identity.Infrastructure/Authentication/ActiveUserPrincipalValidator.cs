using System.Security.Claims;
using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;

namespace Identity.Infrastructure.Authentication;

public sealed class ActiveUserPrincipalValidator(UserManager<User> userManager)
{
    private const string SubjectClaimType = "sub";
    private const string RoleClaimType = "role";

    public async Task<ClaimsPrincipal?> RefreshAsync(ClaimsPrincipal principal)
    {
        var userId = principal.FindFirstValue(SubjectClaimType)
            ?? principal.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId)) return null;

        var user = await userManager.FindByIdAsync(userId);
        if (user is null || user.IsSuspended) return null;

        var currentRoles = await userManager.GetRolesAsync(user);
        var tokenIdentity = principal.Identity as ClaimsIdentity;

        var claims = principal.Claims
            .Where(claim => claim.Type is not RoleClaimType && claim.Type != ClaimTypes.Role)
            .ToList();
        claims.AddRange(currentRoles.Select(role => new Claim(RoleClaimType, role)));

        var refreshedIdentity = new ClaimsIdentity(
            claims,
            tokenIdentity?.AuthenticationType,
            tokenIdentity?.NameClaimType ?? ClaimsIdentity.DefaultNameClaimType,
            RoleClaimType);

        return new ClaimsPrincipal(refreshedIdentity);
    }
}
