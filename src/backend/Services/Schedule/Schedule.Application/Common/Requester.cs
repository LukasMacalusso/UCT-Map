using System;

namespace Schedule.Application.Common;

// The authenticated user making the request, taken from the JWT already validated by the API.
public sealed record Requester(Guid UserId, bool IsAdmin)
{
    public const string AdminRole = "Admin";

    public bool CanAccess(Guid ownerRefId) => IsAdmin || UserId == ownerRefId;
}
