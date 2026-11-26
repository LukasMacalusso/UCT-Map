using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;

namespace Identity.Infrastructure.Identity;

public static class RoleSeeder
{
    private static readonly string[] DefaultRoles =
    [
        Role.Admin,
        Role.Student,
        Role.Teacher,
        Role.ObjectsOfficer,
        Role.ComplaintsOfficer
    ];

    public static async Task EnsureAsync(RoleManager<Role> roleManager)
    {
        ArgumentNullException.ThrowIfNull(roleManager);

        foreach (var roleName in DefaultRoles)
        {
            if (await roleManager.RoleExistsAsync(roleName)) continue;

            var result = await roleManager.CreateAsync(new Role(roleName));

            if (!result.Succeeded && !await roleManager.RoleExistsAsync(roleName))
            {
                throw new InvalidOperationException(
                    $"Role '{roleName}' could not be seeded: {Describe(result)}");
            }
        }
    }

    public static async Task EnsureAdminAsync(
        UserManager<User> userManager,
        IdentitySeedSettings settings,
        ILogger logger)
    {
        ArgumentNullException.ThrowIfNull(userManager);
        ArgumentNullException.ThrowIfNull(settings);
        ArgumentNullException.ThrowIfNull(logger);

        if (await HasActiveAdminAsync(userManager))
        {
            logger.LogInformation("Administrator seed skipped: an active administrator already exists.");
            return;
        }

        if (string.IsNullOrWhiteSpace(settings.AdminEmail) || string.IsNullOrWhiteSpace(settings.AdminPassword))
        {
            logger.LogWarning(
                "No active administrator exists and {Section}:AdminEmail / {Section}:AdminPassword are not configured. The initial administrator was not created.",
                IdentitySeedSettings.SectionName,
                IdentitySeedSettings.SectionName);
            return;
        }

        var adminEmail = settings.AdminEmail.Trim();
        var adminUser = await userManager.FindByEmailAsync(adminEmail);

        if (adminUser is null)
        {
            var createResult = await userManager.CreateAsync(
                User.Create(settings.AdminName, adminEmail),
                settings.AdminPassword);

            adminUser = await userManager.FindByEmailAsync(adminEmail);
            if (adminUser is null)
            {
                throw new InvalidOperationException(
                    $"The initial administrator could not be seeded: {Describe(createResult)}");
            }
        }

        if (adminUser.IsSuspended)
        {
            logger.LogError(
                "No active administrator exists and the configured administrator account is suspended. It was not reactivated automatically.");
            return;
        }

        if (await userManager.IsInRoleAsync(adminUser, Role.Admin)) return;

        var roleResult = await userManager.AddToRoleAsync(adminUser, Role.Admin);
        if (!roleResult.Succeeded && !await userManager.IsInRoleAsync(adminUser, Role.Admin))
        {
            throw new InvalidOperationException(
                $"The Admin role could not be assigned to the initial administrator: {Describe(roleResult)}");
        }

        logger.LogInformation("Initial administrator seeded.");
    }

    private static async Task<bool> HasActiveAdminAsync(UserManager<User> userManager)
    {
        var admins = await userManager.GetUsersInRoleAsync(Role.Admin);
        foreach (var admin in admins)
        {
            if (!admin.IsSuspended) return true;
        }

        return false;
    }

    private static string Describe(IdentityResult result)
    {
        var errorCodes = new List<string>();
        foreach (var error in result.Errors)
        {
            errorCodes.Add(error.Code);
        }

        return string.Join(", ", errorCodes);
    }
}
