using Microsoft.AspNetCore.Identity;

namespace Identity.Domain.Entities;

public class User : IdentityUser
{
    public string Name { get; private set; } = string.Empty;

    public DateTime RegistrationDate { get; private set; } = DateTime.UtcNow;

    public bool IsSuspended { get; private set; }

    public void SetSuspended(bool isSuspended) => IsSuspended = isSuspended;

    public static User Create(string name, string email)
    {
        var normalizedName = name?.Trim() ?? string.Empty;
        var normalizedEmail = email?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(normalizedName))
        {
            throw new ArgumentException("User name is required.", nameof(name));
        }

        if (string.IsNullOrWhiteSpace(normalizedEmail))
        {
            throw new ArgumentException("User email is required.", nameof(email));
        }

        return new User
        {
            Name = normalizedName,
            Email = normalizedEmail,
            UserName = normalizedEmail
        };
    }
}