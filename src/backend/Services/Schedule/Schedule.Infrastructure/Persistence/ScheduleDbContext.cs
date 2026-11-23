using Microsoft.EntityFrameworkCore;
using Schedule.Domain.Entities;

namespace Schedule.Infrastructure.Persistence;

public class ScheduleDbContext : DbContext
{
    public ScheduleDbContext(DbContextOptions<ScheduleDbContext> options)
        : base(options)
    {
    }

    public DbSet<OfficeHour> OfficeHours => Set<OfficeHour>();
    public DbSet<Meeting> Meetings => Set<Meeting>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ScheduleDbContext).Assembly);
    }
}
