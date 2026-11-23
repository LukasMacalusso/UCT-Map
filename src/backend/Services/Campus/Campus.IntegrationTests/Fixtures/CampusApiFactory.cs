using System.Threading.Tasks;
using Campus.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Campus.IntegrationTests.Fixtures;

/// <summary>
/// Arranca la API real (Program.cs completo) reemplazando la base de datos
/// por la instancia efímera de PostgreSQL creada por Testcontainers.
/// </summary>
public sealed class CampusApiFactory : WebApplicationFactory<Program>
{
    private readonly PostgreSqlFixture _fixture;

    public CampusApiFactory(PostgreSqlFixture fixture)
    {
        _fixture = fixture;
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<CampusDbContext>>();
            services.RemoveAll<CampusDbContext>();

            if (_fixture.IsAvailable && !string.IsNullOrEmpty(_fixture.ConnectionString))
            {
                services.AddDbContext<CampusDbContext>(options =>
                    options.UseNpgsql(_fixture.ConnectionString));
            }
        });
    }

    public CampusDbContext CreateDbContext()
    {
        var scope = Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<CampusDbContext>();
    }
}
