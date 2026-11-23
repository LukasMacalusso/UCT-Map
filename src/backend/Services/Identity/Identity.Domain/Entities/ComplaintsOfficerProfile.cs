namespace Identity.Domain.Entities;

public class ComplaintsOfficerProfile
{
    public Guid Id { get; private set; }
    public string UserId { get; private set; } = string.Empty;
    public Guid CampusId { get; private set; }
    public string Type { get; private set; } = "Quejas";
    public string WorkArea { get; private set; } = string.Empty;
    public string Permissions { get; private set; } = string.Empty;
    public string Contact { get; private set; } = string.Empty;
    public string Schedule { get; private set; } = string.Empty;
}
