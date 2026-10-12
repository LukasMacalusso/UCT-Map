using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Schedule.Infrastructure.Persistence;

namespace Schedule.IntegrationTests.Infrastructure;

public class ScheduleApiFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName = $"schedule-tests-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:ScheduleDb", "Host=unused");

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
