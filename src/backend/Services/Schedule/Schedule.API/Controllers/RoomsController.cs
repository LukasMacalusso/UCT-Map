using Microsoft.AspNetCore.Mvc;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
[Route("api/schedule/rooms")]
public class RoomsController : ControllerBase
{
    private readonly RoomHandler _handler;

    public RoomsController(RoomHandler handler) { _handler = handler; }

    [HttpGet("availability")]
    public async Task<ActionResult<RoomAvailabilityDto>> GetAvailability([FromQuery] List<Guid> roomIds, [FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken cancellationToken)
    {
        if (from is null || to is null) return BadRequest(new { message = "The 'from' and 'to' query parameters are required." });
        var result = await _handler.GetAvailabilityAsync(roomIds, from.Value, to.Value, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }
}
