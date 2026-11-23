namespace Identity.Domain.Entities;

public class StudentProfile
{
    public Guid Id { get; private set; }
    public string UserId { get; private set; } = string.Empty;
    public string Name { get; private set; } = string.Empty;
    public string Career { get; private set; } = string.Empty;
    public Guid CampusId { get; private set; }
}
