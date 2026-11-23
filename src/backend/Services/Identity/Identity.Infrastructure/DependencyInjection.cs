using Identity.Application.Interfaces;
using Identity.Application.Handlers;
using Identity.Domain.Entities;
using Identity.Infrastructure.Authentication;
using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Identity.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("IdentityDb")
            ?? throw new InvalidOperationException("Connection string 'IdentityDb' was not found.");

        services.AddDbContext<IdentityDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.Configure<JwtSettings>(configuration.GetSection("JwtConfig"));

        services.AddIdentityCore<User>()
            .AddRoles<Role>()
            .AddEntityFrameworkStores<IdentityDbContext>();

        services.AddScoped<IUserAuthenticator, IdentityUserAuthenticator>();
        services.AddScoped<IUserRegistrationService, IdentityUserRegistrationService>();
        services.AddScoped<IUserQuery, IdentityUserQuery>();
        services.AddScoped<IJwtTokenGenerator, JwtTokenGenerator>();
        services.AddScoped<IRoleManagementService, IdentityRoleManagementService>();
        services.AddScoped<LoginHandler>();
        services.AddScoped<RegisterUserHandler>();
        services.AddScoped<GetUserByIdHandler>();
        services.AddScoped<RoleManagementHandler>();

        return services;
    }
}
