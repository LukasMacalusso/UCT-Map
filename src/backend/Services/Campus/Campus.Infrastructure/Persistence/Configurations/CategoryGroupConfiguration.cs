using Campus.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Campus.Infrastructure.Persistence.Configurations;

public class CategoryGroupConfiguration : IEntityTypeConfiguration<CategoryGroup>
{
    public void Configure(EntityTypeBuilder<CategoryGroup> builder)
    {
        builder.Property(cg => cg.Name)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(cg => cg.Order)
               .IsRequired()
               .HasDefaultValue(0);

        builder.HasMany(cg => cg.Categories)
               .WithOne(c => c.CategoryGroup)
               .HasForeignKey(c => c.CategoryGroupId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
