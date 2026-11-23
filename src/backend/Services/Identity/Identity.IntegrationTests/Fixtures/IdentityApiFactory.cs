using System.Net.Http.Headers;
using System.Net.Http.Json;
using Identity.Application.DTOs;
using Identity.Domain.Entities;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;

namespace Identity.IntegrationTests.Fixtures;

public sealed class IdentityApiFactory : WebApplicationFactory<Program>
{
    public const string Password = "Password123!";

    private readonly string _databaseName = $"identity-tests-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:IdentityDb", "Host=unused");
        builder.UseSetting("JwtConfig:Key", "12345678901234567890123456789012");
        builder.UseSetting("JwtConfig:Issuer", "identity-api");
        builder.UseSetting("JwtConfig:Audience", "api-gateway");
        builder.UseSetting("JwtConfig:TokenValidationMins", "60");

        builder.ConfigureTestServices(services =>
        {
            var npgsqlRegistrations = services
                .Where(d => d.ServiceType == typeof(DbContextOptions<IdentityDbContext>)
                    || d.ServiceType == typeof(IDbContextOptionsConfiguration<IdentityDbContext>))
                .ToList();

            foreach (var registration in npgsqlRegistrations)
            {
                services.Remove(registration);
            }

            services.AddDbContext<IdentityDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
        });
    }

    public async Task<string> CreateUserAsync(string email, params string[] roles)
    {
        using var scope = Services.CreateScope();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
        var user = User.Create("Test User", email);

        var result = await userManager.CreateAsync(user, Password);
        if (!result.Succeeded)
        {
            throw new InvalidOperationException($"Test user '{email}' could not be created.");
        }

        if (roles.Length > 0)
        {
            await userManager.AddToRolesAsync(user, roles);
        }

        return user.Id;
    }

    public async Task<HttpClient> CreateAuthenticatedClientAsync(string email)
    {
        var client = CreateClient();
        var response = await client.PostAsJsonAsync(
            "/api/identity/login",
            new LoginRequest(email, Password));
        response.EnsureSuccessStatusCode();

        var login = await response.Content.ReadFromJsonAsync<LoginResult>()
            ?? throw new InvalidOperationException("Login response was empty.");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", login.Token);
        return client;
    }
}
