using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        var result = await _handler.GetMeetingsAsync(studentId, from, to, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }
}
