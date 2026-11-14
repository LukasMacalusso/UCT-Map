using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Schedule.API.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
[Authorize]
[Route("api/schedule/students")]
public class StudentsController : ControllerBase
{
    private readonly StudentHandler _handler;

    public StudentsController(StudentHandler handler) { _handler = handler; }

    [HttpGet("{studentId:guid}/meetings")]
    public async Task<ActionResult<StudentMeetingsDto>> GetMeetings(Guid studentId, [FromQuery] DateTime from, [FromQuery] DateTime to, CancellationToken cancellationToken)
    {
        if (studentId == Guid.Empty) return BadRequest(new { message = "The 'studentId' path parameter is required." });
        var requester = User.ToRequester();
        if (requester is null) return Unauthorized(new { message = ErrorResults.MissingUserMessage });

        var result = await _handler.GetMeetingsAsync(studentId, from, to, requester, cancellationToken);
        if (result.IsError) return this.ToActionResult(result.FirstError);
        return Ok(result.Value);
    }
}
