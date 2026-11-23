using Identity.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;

namespace Identity.API.Controllers;

[ApiController]
[Route("health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            service = "identity-service",
            status = "healthy"
        });
    }

    [HttpGet("database")]
    public async Task<IActionResult> GetDatabaseStatus(
        [FromServices] IdentityDbContext db,
        CancellationToken cancellationToken)
    {
        try
        {
            var connected = await db.Database.CanConnectAsync(cancellationToken);

            return connected
                ? Ok(new
                {
                    database = "identity",
                    status = "connected"
                })
                : StatusCode(StatusCodes.Status503ServiceUnavailable, new
                {
                    database = "identity",
                    status = "unavailable"
                });
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                database = "identity",
                status = "unavailable"
            });
        }
    }
}