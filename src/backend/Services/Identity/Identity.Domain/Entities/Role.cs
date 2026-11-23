using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Entities;

public class Role : IdentityRole
{
    public const string Admin = "Admin";
    public const string Student = "Student";
    public const string Teacher = "Teacher";
    public const string ObjectsOfficer = "ObjectsOfficer";
    public const string ComplaintsOfficer = "ComplaintsOfficer";

    public string? Description { get; set; }

    public Role()
    {
    }

    public Role(string name)
        : base(name)
    {
    }

    public Role(string name, string description)
        : base(name)
    {
        Description = description;
    }
}
