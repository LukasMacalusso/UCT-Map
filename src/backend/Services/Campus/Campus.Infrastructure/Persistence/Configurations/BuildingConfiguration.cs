using Campus.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Campus.Infrastructure.Persistence.Configurations;

public class BuildingConfiguration : IEntityTypeConfiguration<Building>
{
    public void Configure(EntityTypeBuilder<Building> builder)
    {
        builder.Property(b => b.Name)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(b => b.FloorsCount)
               .IsRequired();

        builder.Property(b => b.OpenTime)
               .HasColumnType("time")
               .IsRequired(false);

        builder.Property(b => b.CloseTime)
               .HasColumnType("time")
               .IsRequired(false);

        builder.Property(b => b.Services)
               .IsRequired(false)
               .HasMaxLength(150);

        builder.HasMany(b => b.Rooms)
               .WithOne(r => r.Building)
               .HasForeignKey(r => r.BuildingId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.OwnsOne(b => b.Coordinates);
    }
}
