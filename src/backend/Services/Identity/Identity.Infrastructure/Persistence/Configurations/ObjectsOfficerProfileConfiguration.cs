using Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Identity.Infrastructure.Persistence.Configurations;

public class ObjectsOfficerProfileConfiguration : IEntityTypeConfiguration<ObjectsOfficerProfile>
{
    public void Configure(EntityTypeBuilder<ObjectsOfficerProfile> builder)
    {
        builder.ToTable("ObjectsOfficerProfiles");
        builder.HasOne<User>().WithMany().HasForeignKey(profile => profile.UserId);
    }
}
