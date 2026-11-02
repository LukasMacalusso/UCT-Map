using Campus.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Campus.Infrastructure.Persistence.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.Property(c => c.Name)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(c => c.Icon)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(c => c.Description)
               .IsRequired(false)
               .HasMaxLength(250);

        builder.Property(c => c.Order)
               .IsRequired()
               .HasDefaultValue(0);

        builder.HasMany(c => c.Structures)
               .WithOne(s => s.Category)
               .HasForeignKey(s => s.CategoryId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasMany(c => c.Rooms)
               .WithOne(r => r.Category)
               .HasForeignKey(r => r.CategoryId)
               .OnDelete(DeleteBehavior.SetNull);
    }
}
