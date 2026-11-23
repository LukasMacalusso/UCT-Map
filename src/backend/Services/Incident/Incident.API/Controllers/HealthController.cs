using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Incident.API.Controllers;

[ApiController]
[Route("[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet] // GET /health
    public IActionResult Get() =>
        Ok(new { service = "incident-service", status = "healthy" });

    [HttpGet("ready")] // GET /health/ready
    public async Task<IActionResult> Ready([FromServices] IMongoClient mongo)
    {
        try
        {
            await mongo.GetDatabase("admin")
                       .RunCommandAsync<BsonDocument>(new BsonDocument("ping", 1));
            return Ok(new
            {
                service = "incident-service",
                status = "ready",
                database = "connected"
            });
        }
        catch
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                service = "incident-service",
                status = "unhealthy",
                database = "disconnected"
            });
        }
    }
}
