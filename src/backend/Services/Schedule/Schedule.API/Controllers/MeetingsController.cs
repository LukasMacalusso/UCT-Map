using ErrorOr;
using Microsoft.AspNetCore.Mvc;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
[Route("api/schedule/meetings")]
public class MeetingsController : ControllerBase
{
    private readonly MeetingHandler _handler;

    public MeetingsController(MeetingHandler handler) { _handler = handler; }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<MeetingDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _handler.GetByIdAsync(id, cancellationToken);
        if (result.IsError) return NotFound(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MeetingDto>>> Get([FromQuery] Guid? teacherId, [FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken cancellationToken)
    {
        if (teacherId is null)
        {
            var all = await _handler.GetAllAsync(cancellationToken);
            return Ok(all.Value);
        }

        if (teacherId == Guid.Empty) return BadRequest(new { message = "The 'teacherId' query parameter cannot be empty." });
        if (from is null || to is null) return BadRequest(new { message = "The 'from' and 'to' query parameters are required when filtering by teacher." });
        var result = await _handler.GetByTeacherAsync(teacherId.Value, from.Value, to.Value, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }

    [HttpPost]
    public async Task<ActionResult<MeetingDto>> Create([FromBody] CreateMeetingRequest request, CancellationToken cancellationToken)
    {
        var result = await _handler.CreateAsync(request, cancellationToken);
        if (result.IsError)
        {
            return result.FirstError.Type == ErrorType.Conflict
                ? Conflict(new { message = result.FirstError.Description })
                : BadRequest(new { message = result.FirstError.Description });
        }

        return CreatedAtAction(nameof(GetById), new { id = result.Value.Id }, result.Value);
    }

    [HttpPatch("{id:guid}/cancel")]
    public async Task<ActionResult<MeetingDto>> Cancel(Guid id, CancellationToken cancellationToken)
    {
        var requesterRefId = JwtUserIdReader.GetUserId(Request.Headers.Authorization.ToString());
        if (requesterRefId is null) return Unauthorized(new { message = "A valid token with the user id is required." });

        var result = await _handler.CancelAsync(id, requesterRefId.Value, cancellationToken);
        if (result.IsError)
        {
            var body = new { message = result.FirstError.Description };
            return result.FirstError.Type switch
            {
                ErrorType.NotFound => NotFound(body),
                ErrorType.Forbidden => StatusCode(StatusCodes.Status403Forbidden, body),
                _ => Conflict(body)
            };
        }

        return Ok(result.Value);
    }
}
