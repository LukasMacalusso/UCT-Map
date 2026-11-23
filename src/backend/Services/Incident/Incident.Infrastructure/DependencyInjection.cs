using Incident.Application.Handlers;
using Incident.Domain.Interfaces;
using Incident.Infrastructure.Persistence;
using Incident.Infrastructure.Persistence.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MongoDB.Driver;

namespace Incident.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        MongoDbConfiguration.RegisterClassMaps();
        var connectionString = configuration["MongoDB:ConnectionString"]
                               ?? "mongodb://root:rootpassword@mongodb:27017/?authSource=admin";

        var databaseName = configuration["MongoDB:DatabaseName"]
                           ?? "uct_incident_db";

        services.AddSingleton<IMongoClient>(new MongoClient(connectionString));

        services.AddScoped<IMongoDatabase>(sp =>
        {
            var client = sp.GetRequiredService<IMongoClient>();
            return client.GetDatabase(databaseName);
        });

        services.AddScoped<IMongoDbContext>(sp =>
        {
            var client = sp.GetRequiredService<IMongoClient>();
            return new MongoDbContext(client, databaseName);
        });

        services.AddScoped<ITicketRepository, TicketRepository>();
        services.AddScoped<IReportHandler, ReportHandler>();
        services.AddScoped<ILostObjectRepository, ObjectRepository>();
        services.AddScoped<ILostObjectHandler, LostObjectHandler>();
        return services;
    }
}
