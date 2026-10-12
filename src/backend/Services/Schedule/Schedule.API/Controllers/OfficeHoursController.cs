using Microsoft.AspNetCore.Mvc;
using Schedule.Application.DTOs;
using Schedule.Application.Handlers;

namespace Schedule.API.Controllers;

[ApiController]
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
        var result = await _handler.CreateAsync(request, cancellationToken);
        if (result.IsError) return BadRequest(new { message = result.FirstError.Description });
        return CreatedAtAction(nameof(GetById), new { id = result.Value.Id }, result.Value);
    }
}
