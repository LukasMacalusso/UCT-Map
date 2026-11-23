namespace Identity.Application.DTOs;

public sealed record RoleReplacementRequest(IReadOnlyList<string> Roles);
