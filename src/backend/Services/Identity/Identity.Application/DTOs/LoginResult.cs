namespace Identity.Application.DTOs;

public sealed record LoginResult(string UserId, string Email, string Name, string? Token = null);