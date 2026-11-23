using Identity.Application.DTOs;
namespace Identity.Infrastructure.Authentication;

public sealed class JwtSettings
{
    public string Issuer { get; set; } = string.Empty;

    public string Audience { get; set; } = string.Empty;

    public string Key { get; set; } = string.Empty;

    public int TokenValidationMins { get; set; } = 30;
}