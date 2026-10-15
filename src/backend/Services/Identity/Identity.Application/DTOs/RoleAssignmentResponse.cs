namespace Identity.Application.DTOs;

public sealed record RoleAssignmentResponse(
    string UserId,
    IReadOnlyList<string> Roles,
    bool IsSuspended);
