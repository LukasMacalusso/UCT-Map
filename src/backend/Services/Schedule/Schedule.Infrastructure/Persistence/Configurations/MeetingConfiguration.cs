using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Schedule.Domain.Entities;

namespace Schedule.Infrastructure.Persistence.Configurations;

public class MeetingConfiguration : IEntityTypeConfiguration<Meeting>
{
    public void Configure(EntityTypeBuilder<Meeting> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.TeacherRefId)
            .IsRequired();

        builder.Property(m => m.StudentRefId)
            .IsRequired();

        builder.Property(m => m.StructureRefId);

        builder.Property(m => m.ScheduledAt)
            .HasColumnType("timestamp without time zone")
            .IsRequired();

        builder.Property(m => m.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.HasIndex(m => new { m.TeacherRefId, m.ScheduledAt });
        builder.HasIndex(m => new { m.StudentRefId, m.ScheduledAt });
        builder.HasIndex(m => new { m.StructureRefId, m.ScheduledAt });
    }
}

