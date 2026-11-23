using Identity.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Identity.Infrastructure.Persistence.Configurations;

public class ComplaintsOfficerProfileConfiguration : IEntityTypeConfiguration<ComplaintsOfficerProfile>
{
    public void Configure(EntityTypeBuilder<ComplaintsOfficerProfile> builder)
    {
        builder.ToTable("ComplaintsOfficerProfiles");
        builder.HasOne<User>().WithMany().HasForeignKey(profile => profile.UserId);
    }
}
