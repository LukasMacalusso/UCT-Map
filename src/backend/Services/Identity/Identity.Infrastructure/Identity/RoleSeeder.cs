using Identity.Domain.Entities;
using Microsoft.AspNetCore.Identity;

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
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new Role(roleName));
            }
        }
    }

    public static async Task EnsureAsync(RoleManager<Role> roleManager, UserManager<User> userManager)
    {
        await EnsureAsync(roleManager);
        ArgumentNullException.ThrowIfNull(userManager);

        const string adminEmail = "admin@uct.cl";
        var adminUser = await userManager.FindByEmailAsync(adminEmail);

        if (adminUser is null)
        {
            adminUser = User.Create("Admin UCT", adminEmail);
            var result = await userManager.CreateAsync(adminUser, "Sprint2!");
            if (!result.Succeeded) return;
        }

        if (!await userManager.IsInRoleAsync(adminUser, Role.Admin))
        {
            await userManager.AddToRoleAsync(adminUser, Role.Admin);
        }
    }
}
