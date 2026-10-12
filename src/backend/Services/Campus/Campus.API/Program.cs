using Microsoft.EntityFrameworkCore;
using Campus.Infrastructure.Persistence;
using Campus.Domain.Interfaces;
using Campus.Application.Handlers;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<CampusDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("CampusDb")));

// DI Registrations
builder.Services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
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
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.Run();

public partial class Program { }
