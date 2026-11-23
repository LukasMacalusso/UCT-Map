namespace Identity.Domain.Entities;

public class TeacherProfile
{
    public Guid Id { get; private set; }
    public string UserId { get; private set; } = string.Empty;
    public string RegistrationNumber { get; private set; } = string.Empty;
    public string InstitutionalEmail { get; private set; } = string.Empty;
    public string Department { get; private set; } = string.Empty;
    public string WorkScheduleType { get; private set; } = string.Empty;
    public Guid OfficeStructureId { get; private set; }
    public string CoursesInCharge { get; private set; } = string.Empty;
    public string Schedules { get; private set; } = string.Empty;
}
