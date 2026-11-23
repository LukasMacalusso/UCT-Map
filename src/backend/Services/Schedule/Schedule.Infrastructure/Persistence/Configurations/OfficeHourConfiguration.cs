using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Schedule.Domain.Entities;

namespace Schedule.Infrastructure.Persistence.Configurations;

public class OfficeHourConfiguration : IEntityTypeConfiguration<OfficeHour>
{
    public void Configure(EntityTypeBuilder<OfficeHour> builder)
    {
        builder.HasKey(o => o.Id);

        builder.Property(o => o.TeacherRefId)
            .IsRequired();

        builder.Property(o => o.StructureRefId);

        builder.Property(o => o.DayOfWeek)
            .HasConversion<string>()
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(o => o.StartTime)
            .HasColumnType("time")
            .IsRequired();

        builder.Property(o => o.EndTime)
            .HasColumnType("time")
            .IsRequired();

        builder.HasIndex(o => new { o.TeacherRefId, o.DayOfWeek });
        builder.HasIndex(o => new { o.StructureRefId, o.DayOfWeek });
    }
}

