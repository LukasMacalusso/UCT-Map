using Identity.Domain.Entities;
using Identity.Infrastructure;
using Identity.Infrastructure.Identity;
using Identity.Infrastructure.Persistence;
using Identity.Infrastructure.Authentication;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.EntityFrameworkCore;
using System.Text;
using Microsoft.Extensions.Options;

const string MigrateArgument = "--migrate";

var migrateOnly = false;
var hostArguments = new List<string>();
foreach (var argument in args)
{
    if (string.Equals(argument, MigrateArgument, StringComparison.OrdinalIgnoreCase))
    {
        migrateOnly = true;
        continue;
    }

    hostArguments.Add(argument);
}

var builder = WebApplication.CreateBuilder(hostArguments.ToArray());

if (migrateOnly)
{
    var migrationConnectionString = builder.Configuration.GetConnectionString("IdentityDbMigrations");
    if (!string.IsNullOrWhiteSpace(migrationConnectionString))
    {
        builder.Configuration["ConnectionStrings:IdentityDb"] = migrationConnectionString;
    }
}

builder.Services.AddInfrastructure(builder.Configuration);

if (migrateOnly)
{
    await using var migrationHost = builder.Build();
    return await InitializeDatabaseAsync(migrationHost.Services, migrationHost.Logger) ? 0 : 1;
}

var jwtSettings = builder.Configuration
    .GetSection("JwtConfig")
    .Get<JwtSettings>()
    ?? throw new InvalidOperationException("JWT configuration was not found.");
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidAudience = jwtSettings.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
            RoleClaimType = "role"
        };
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var validator = context.HttpContext.RequestServices
                    .GetRequiredService<ActiveUserPrincipalValidator>();
                var principal = await validator.RefreshAsync(context.Principal!);

                if (principal is null)
                {
                    context.Fail("The user no longer exists or is suspended.");
                    return;
                }

                context.Principal = principal;
            }
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddControllers();

var app = builder.Build();

var databaseSettings = app.Services.GetRequiredService<IOptions<DatabaseInitializationSettings>>().Value;
if (databaseSettings.ApplyMigrationsOnStartup)
{
    if (!await InitializeDatabaseAsync(app.Services, app.Logger))
    {
        throw new InvalidOperationException("Identity database initialization failed. See the previous log entries.");
    }
}
else
{
    app.Logger.LogInformation(
        "Database:ApplyMigrationsOnStartup is disabled. Run `dotnet Identity.API.dll {Argument}` as a release step.",
        MigrateArgument);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
return 0;

static async Task<bool> InitializeDatabaseAsync(IServiceProvider services, ILogger logger)
{
    try
    {
        await using var scope = services.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<IdentityDatabaseInitializer>().InitializeAsync();
        return true;
    }
    catch (Exception exception)
    {
        logger.LogCritical(exception, "Identity database initialization failed.");
        return false;
    }
}

public partial class Program
{
}
