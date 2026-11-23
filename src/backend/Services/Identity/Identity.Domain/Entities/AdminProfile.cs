namespace Identity.Domain.Entities;

public class AdminProfile
{
    public Guid Id { get; private set; }
    public string UserId { get; private set; } = string.Empty;
    public string Permissions { get; private set; } = string.Empty;
    public string Position { get; private set; } = string.Empty;
}
