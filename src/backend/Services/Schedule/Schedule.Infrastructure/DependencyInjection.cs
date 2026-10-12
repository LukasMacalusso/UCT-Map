using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Schedule.Application.Handlers;
using Schedule.Domain.Interfaces;
using Schedule.Infrastructure.Persistence;
using Schedule.Infrastructure.Persistence.Repositories;

namespace Schedule.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("ScheduleDb")
            ?? throw new InvalidOperationException(
                "Connection string 'ScheduleDb' was not found.");

        services.AddDbContext<ScheduleDbContext>(options =>
            options.UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsHistoryTable("__EFMigrationsHistory_Schedule")));

        services.AddScoped<IOfficeHourRepository, OfficeHourRepository>();
        services.AddScoped<IMeetingRepository, MeetingRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<OfficeHourHandler>();
        services.AddScoped<MeetingHandler>();
        services.AddScoped<TeacherHandler>();
        services.AddScoped<StudentHandler>();

        return services;
    }
}
