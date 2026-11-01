using Incident.Application.Handlers;
using Incident.Domain.Interfaces;
using Incident.Infrastructure;
using Incident.Infrastructure.Persistence;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Driver;

namespace Incident.UnitTests.Infrastructure;

/// <summary>
/// Cubre el registro de dependencias del microservicio, incluidos los valores
/// por defecto cuando la configuración no define MongoDB.
/// </summary>
public class DependencyInjectionTests
{
    private static IServiceProvider BuildProvider(Dictionary<string, string?> values)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(values)
            .Build();

        var services = new ServiceCollection();
        services.AddInfrastructure(configuration);
        return services.BuildServiceProvider();
    }

    [Fact]
    public void AddInfrastructure_SinConfiguracion_RegistraLosServiciosYUsaLaBasePorDefecto()
    {
        using var provider = (ServiceProvider)BuildProvider(new Dictionary<string, string?>());

        Assert.NotNull(provider.GetService<IMongoClient>());
        Assert.NotNull(provider.GetService<IMongoDbContext>());
        Assert.NotNull(provider.GetService<ITicketRepository>());
        Assert.NotNull(provider.GetService<ILostObjectRepository>());
        Assert.NotNull(provider.GetService<IReportHandler>());
        Assert.NotNull(provider.GetService<ILostObjectHandler>());

        var context = provider.GetRequiredService<IMongoDbContext>();
        Assert.Equal("uct_incident_db", context.Database.DatabaseNamespace.DatabaseName);

        var database = provider.GetRequiredService<IMongoDatabase>();
        Assert.Equal("uct_incident_db", database.DatabaseNamespace.DatabaseName);
    }

    [Fact]
    public void AddInfrastructure_ConConfiguracion_UsaLosValoresIndicados()
    {
        using var provider = (ServiceProvider)BuildProvider(new Dictionary<string, string?>
        {
            ["MongoDB:ConnectionString"] = "mongodb://localhost:27018",
            ["MongoDB:DatabaseName"] = "incident_custom_db"
        });

        var context = provider.GetRequiredService<IMongoDbContext>();
        Assert.Equal("incident_custom_db", context.Database.DatabaseNamespace.DatabaseName);

        var database = provider.GetRequiredService<IMongoDatabase>();
        Assert.Equal("incident_custom_db", database.DatabaseNamespace.DatabaseName);
    }

    [Fact]
    public void AddInfrastructure_RegistraLosRepositoriosConSuImplementacionConcreta()
    {
        using var provider = (ServiceProvider)BuildProvider(new Dictionary<string, string?>());

        Assert.IsType<Incident.Infrastructure.Persistence.Repositories.TicketRepository>(
            provider.GetRequiredService<ITicketRepository>());
        Assert.IsType<Incident.Infrastructure.Persistence.Repositories.ObjectRepository>(
            provider.GetRequiredService<ILostObjectRepository>());
    }
}
