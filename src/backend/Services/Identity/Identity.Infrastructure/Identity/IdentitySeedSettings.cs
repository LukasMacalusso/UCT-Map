namespace Identity.Infrastructure.Identity;

public sealed class IdentitySeedSettings
{
    public const string SectionName = "IdentitySeed";

    public string AdminName { get; init; } = "Admin UCT";

    public string? AdminEmail { get; init; }

    public string? AdminPassword { get; init; }
}
