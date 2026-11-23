using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace Identity.Infrastructure.Persistence;

public class IdentityDbContext : IdentityDbContext<User, Role, string>
{
    public DbSet<AdminProfile> Admins => Set<AdminProfile>();
    public DbSet<StudentProfile> Students => Set<StudentProfile>();
    public DbSet<TeacherProfile> Teachers => Set<TeacherProfile>();
    public DbSet<ObjectsOfficerProfile> ObjectsOfficers => Set<ObjectsOfficerProfile>();
    public DbSet<ComplaintsOfficerProfile> ComplaintsOfficers => Set<ComplaintsOfficerProfile>();

    public IdentityDbContext(DbContextOptions<IdentityDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        builder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}
