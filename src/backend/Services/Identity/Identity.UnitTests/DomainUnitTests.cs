using Identity.Domain.Entities;

namespace Identity.UnitTests;

public sealed class DomainUnitTests
{
    [Fact]
    public void UserCreate_TrimsValuesAndUsesEmailAsUserName()
    {
        var user = User.Create("  Ana Torres ", " ana@uct.cl ");

        Assert.Equal("Ana Torres", user.Name);
        Assert.Equal("ana@uct.cl", user.UserName);
        Assert.False(user.IsSuspended);
        Assert.True(user.RegistrationDate <= DateTime.UtcNow);
    }

    [Theory]
    [InlineData("", "ana@uct.cl", "name")]
    [InlineData("Ana", " ", "email")]
    public void UserCreate_WhenRequiredValueIsMissing_Throws(string name, string email, string parameter)
    {
        var exception = Assert.Throws<ArgumentException>(() => User.Create(name, email));

        Assert.Equal(parameter, exception.ParamName);
    }

    [Fact]
    public void Role_StoresNameAndDescription()
    {
        var role = new Role(Role.Admin, "System administrator");

        Assert.Equal(Role.Admin, role.Name);
        Assert.Equal("System administrator", role.Description);
        Assert.Null(new Role().Description);
    }

    [Fact]
    public void Profiles_HaveExpectedDefaults()
    {
        var admin = new AdminProfile();
        var student = new StudentProfile();
        var teacher = new TeacherProfile();
        var objectsOfficer = new ObjectsOfficerProfile();
        var complaintsOfficer = new ComplaintsOfficerProfile();

        Assert.Equal(string.Empty, admin.UserId + admin.Permissions + admin.Position);
        Assert.Equal(Guid.Empty, admin.Id);
        Assert.Equal(string.Empty, student.UserId + student.Name + student.Career);
        Assert.Equal(Guid.Empty, student.Id);
        Assert.Equal(Guid.Empty, student.CampusId);
        Assert.Equal(
            string.Empty,
            teacher.UserId + teacher.RegistrationNumber + teacher.InstitutionalEmail + teacher.Department
                + teacher.WorkScheduleType + teacher.CoursesInCharge + teacher.Schedules);
        Assert.Equal(Guid.Empty, teacher.Id);
        Assert.Equal(Guid.Empty, teacher.OfficeStructureId);
        Assert.Equal("ObjetosPerdidos", objectsOfficer.Type);
        Assert.Equal(
            string.Empty,
            objectsOfficer.UserId + objectsOfficer.WorkArea + objectsOfficer.Permissions
                + objectsOfficer.Contact + objectsOfficer.Schedule);
        Assert.Equal(Guid.Empty, objectsOfficer.Id);
        Assert.Equal(Guid.Empty, objectsOfficer.CampusId);
        Assert.Equal("Quejas", complaintsOfficer.Type);
        Assert.Equal(
            string.Empty,
            complaintsOfficer.UserId + complaintsOfficer.WorkArea + complaintsOfficer.Permissions
                + complaintsOfficer.Contact + complaintsOfficer.Schedule);
        Assert.Equal(Guid.Empty, complaintsOfficer.Id);
        Assert.Equal(Guid.Empty, complaintsOfficer.CampusId);
    }
}
