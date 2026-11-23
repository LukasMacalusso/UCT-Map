using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Campus.Infrastructure.Persistence;
using Campus.Infrastructure.Persistence.Repositories;
using Campus.Domain.Interfaces;
using Campus.Application.Handlers;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var jwtKey = builder.Configuration["JwtConfig:Key"]
    ?? throw new InvalidOperationException("JWT setting 'JwtConfig:Key' was not found.");
var jwtIssuer = builder.Configuration["JwtConfig:Issuer"] ?? "https://identity-api";
var jwtAudience = builder.Configuration["JwtConfig:Audience"] ?? "api-gateway";

builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            RoleClaimType = System.Security.Claims.ClaimTypes.Role
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddDbContext<CampusDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("CampusDb")));

// DI Registrations
builder.Services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
builder.Services.AddScoped<ICampusRepository, CampusRepository>();
builder.Services.AddScoped<CampusHandler>();
builder.Services.AddScoped<BuildingHandler>();
builder.Services.AddScoped<CategoryHandler>();
builder.Services.AddScoped<RoomHandler>();
builder.Services.AddScoped<StructureHandler>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<CampusDbContext>();
    await context.Database.MigrateAsync();
    await CampusDbContextSeed.SeedAsync(context);
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

public partial class Program { }
