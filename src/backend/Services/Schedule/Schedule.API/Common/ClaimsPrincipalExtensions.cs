using System.Security.Claims;
using Microsoft.IdentityModel.JsonWebTokens;
using Schedule.Application.Common;

namespace Schedule.API.Common;

public static class ClaimsPrincipalExtensions
{
    // Identity puts the user id in "sub" and the roles in "role" (inbound claim mapping is off).
    public static Requester? ToRequester(this ClaimsPrincipal user)
    {
        var userId = user.FindFirstValue(JwtRegisteredClaimNames.Sub);
        return Guid.TryParse(userId, out var id)
            ? new Requester(id, user.IsInRole(Requester.AdminRole))
            : null;
    }
}
