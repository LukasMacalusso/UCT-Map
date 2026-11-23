using Campus.Domain.Entities;
using CampusEntity = Campus.Domain.Entities.Campus;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Campus.Infrastructure.Persistence.Configurations;

public class CampusConfiguration : IEntityTypeConfiguration<CampusEntity>
{
    public void Configure(EntityTypeBuilder<CampusEntity> builder)
    {
        builder.Property(c => c.Name)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(c => c.Address)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(c => c.Zoom)
               .HasPrecision(4, 2)
               .IsRequired();

        builder.Property(c => c.Pitch)
               .HasPrecision(4, 2)
               .IsRequired();

        builder.Property(c => c.Bearing)
               .HasPrecision(5, 2)
               .IsRequired();

        builder.HasMany(c => c.Buildings)
               .WithOne(b => b.Campus)
               .HasForeignKey(b => b.CampusId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(c => c.Structures)
               .WithOne(s => s.Campus)
               .HasForeignKey(s => s.CampusId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.OwnsOne(c => c.Coordinates);
    }
}
