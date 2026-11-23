using Incident.Infrastructure;
using Incident.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

MongoDbConfiguration.RegisterClassMaps();
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddInfrastructure(builder.Configuration);

// Confía en el ApiGateway: extrae los claims del JWT sin validar firma,
// issuer, audience ni expiración. El gateway ya validó el token.
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = false,
            ValidateIssuerSigningKey = false,
            RequireSignedTokens = false,
            SignatureValidator = (token, _) => new JsonWebToken(token),
            RoleClaimType = "role"
        };
        options.Events = new JwtBearerEvents
        {
            OnForbidden = async context =>
            {
                if (context.Response.HasStarted)
                    return;

                context.Response.StatusCode = StatusCodes.Status403Forbidden;

                await context.Response.WriteAsJsonAsync(
                    new ProblemDetails
                    {
                        Type = "https://tools.ietf.org/html/rfc9110#section-15.5.4",
                        Title = "Forbidden",
                        Status = StatusCodes.Status403Forbidden,
                        Detail = "No tienes permisos para realizar esta acción.",
                        Instance = context.Request.Path
                    },
                    options: null,
                    contentType: "application/problem+json");
            }
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddProblemDetails();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler();
app.UseAuthentication();
app.UseAuthorization();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();

app.Run();

public partial class Program
{
}
