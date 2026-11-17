using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Schedule.Infrastructure.Persistence;

namespace Schedule.IntegrationTests.Infrastructure;

public class ScheduleApiFactory : WebApplicationFactory<Program>
{
    public const string AdminRole = "Admin";
    public const string StudentRole = "Student";
    public const string TeacherRole = "Teacher";

    private const string JwtIssuer = "https://identity-api";
    private const string JwtAudience = "api-gateway";
    private const string JwtKey = "schedule-tests-signing-key-0123456789abcdef";

    private readonly string _databaseName = $"schedule-tests-{Guid.NewGuid()}";

    // Builds a token like the ones Identity issues (same claims, issuer and audience).
    public static string CreateToken(Guid userId, string role, string signingKey = JwtKey)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey));
        var token = new JwtSecurityToken(
            issuer: JwtIssuer,
            audience: JwtAudience,
            claims: [new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()), new Claim("role", role)],
            expires: DateTime.UtcNow.AddMinutes(30),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public HttpClient CreateClientAs(Guid userId, string role)
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken(userId, role));
        return client;
    }

    public HttpClient CreateAdminClient() => CreateClientAs(Guid.NewGuid(), AdminRole);

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:ScheduleDb", "Host=unused");
        builder.UseSetting("JwtConfig:Issuer", JwtIssuer);
        builder.UseSetting("JwtConfig:Audience", JwtAudience);
        builder.UseSetting("JwtConfig:Key", JwtKey);

        builder.ConfigureTestServices(services =>
        {
            var npgsqlRegistrations = services
                .Where(d => d.ServiceType == typeof(DbContextOptions<ScheduleDbContext>)
                    || d.ServiceType == typeof(IDbContextOptionsConfiguration<ScheduleDbContext>))
                .ToList();

            foreach (var registration in npgsqlRegistrations)
            {
                services.Remove(registration);
            }

            services.AddDbContext<ScheduleDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
        });
    }
}
