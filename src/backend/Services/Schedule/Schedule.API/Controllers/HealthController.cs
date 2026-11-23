using Microsoft.AspNetCore.Mvc;
using Schedule.Infrastructure.Persistence;

namespace Schedule.API.Controllers;

[ApiController]
[Route("health")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public IActionResult Get()
    {
        return Ok(new
        {
            service = "schedule-service",
            status = "healthy"
        });
    }

    [HttpGet("database")]
    public async Task<IActionResult> GetDatabaseStatus(
        [FromServices] ScheduleDbContext dbContext,
        CancellationToken cancellationToken)
    {
        try
        {
            var connected = await dbContext.Database.CanConnectAsync(cancellationToken);

            return connected
                ? Ok(new { database = "schedule", status = "connected" })
                : StatusCode(StatusCodes.Status503ServiceUnavailable,
                    new { database = "schedule", status = "unavailable" });
        }
        catch (Exception)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { database = "schedule", status = "unavailable" });
        }
    }
}
