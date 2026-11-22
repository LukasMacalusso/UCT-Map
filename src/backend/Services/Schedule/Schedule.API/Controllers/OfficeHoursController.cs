using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Schedule.API.Common;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
[Authorize]
[Route("api/schedule/office-hours")]
public class OfficeHoursController : ControllerBase
{
    private readonly OfficeHourHandler _handler;

    public OfficeHoursController(OfficeHourHandler handler) { _handler = handler; }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<OfficeHourDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _handler.GetByIdAsync(id, cancellationToken);
        if (result.IsError) return NotFound(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<OfficeHourDto>>> Get([FromQuery] Guid? teacherId, CancellationToken cancellationToken)
    {
        if (teacherId == Guid.Empty) return BadRequest(new { message = "The 'teacherId' query parameter cannot be empty." });
        var result = teacherId is null
            ? await _handler.GetAllAsync(cancellationToken)
            : await _handler.GetByTeacherAsync(teacherId.Value, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return Ok(result.Value);
    }

    [HttpPost]
    public async Task<ActionResult<OfficeHourDto>> Create([FromBody] CreateOfficeHourRequest request, CancellationToken cancellationToken)
    {
        var requester = User.ToRequester();
        if (requester is null) return Unauthorized(new { message = ErrorResults.MissingUserMessage });

        var result = await _handler.CreateAsync(request, requester, cancellationToken);
        if (result.IsError) return this.ToActionResult(result.FirstError);
        return CreatedAtAction(nameof(GetById), new { id = result.Value.Id }, result.Value);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<OfficeHourDto>> Update(Guid id, [FromBody] UpdateOfficeHourRequest request, CancellationToken cancellationToken)
    {
        var requester = User.ToRequester();
        if (requester is null) return Unauthorized(new { message = ErrorResults.MissingUserMessage });

        var result = await _handler.UpdateAsync(id, request, requester, cancellationToken);
        if (result.IsError) return this.ToActionResult(result.FirstError);
        return Ok(result.Value);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var requester = User.ToRequester();
        if (requester is null) return Unauthorized(new { message = ErrorResults.MissingUserMessage });

        var result = await _handler.DeleteAsync(id, requester, cancellationToken);
        if (result.IsError) return this.ToActionResult(result.FirstError);
        return NoContent();
    }
}
