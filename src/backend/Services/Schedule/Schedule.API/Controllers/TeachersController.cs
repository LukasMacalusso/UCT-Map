using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Schedule.API.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
[Authorize]
[Route("api/schedule/teachers")]
public class TeachersController : ControllerBase
{
    private readonly TeacherHandler _handler;

    public TeachersController(TeacherHandler handler) { _handler = handler; }

    [HttpGet("{teacherId:guid}/workload")]
    public async Task<ActionResult<TeacherWorkloadDto>> GetWorkload(Guid teacherId, [FromQuery] DateTime from, [FromQuery] DateTime to, CancellationToken cancellationToken)
    {
        if (teacherId == Guid.Empty) return BadRequest(new { message = "The 'teacherId' path parameter is required." });
        var requester = User.ToRequester();
        if (requester is null) return Unauthorized(new { message = ErrorResults.MissingUserMessage });

        var result = await _handler.GetWorkloadAsync(teacherId, from, to, requester, cancellationToken);
        if (result.IsError) return this.ToActionResult(result.FirstError);
        return Ok(result.Value);
    }

    [HttpGet("{teacherId:guid}/availability")]
    public async Task<ActionResult<TeacherAvailabilityDto>> GetAvailability(Guid teacherId, CancellationToken cancellationToken)
    {
        if (teacherId == Guid.Empty) return BadRequest(new { message = "The 'teacherId' path parameter is required." });
        var result = await _handler.GetAvailabilityAsync(teacherId, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }
}
