using Microsoft.AspNetCore.Mvc;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;

namespace Campus.API.Controllers;

[ApiController]
[Route("api/campus/campuses")]
public class CampusController : ControllerBase
{
    private readonly CampusHandler _handler;

    public CampusController(CampusHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CampusDto>>> GetAll(CancellationToken cancellationToken)
    {
        var campuses = await _handler.GetAllAsync(cancellationToken);
        return Ok(campuses);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CampusDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var dto = await _handler.GetByIdAsync(id, cancellationToken);
        if (dto is null) return NotFound(new { message = $"Campus with ID '{id}' was not found." });
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<CampusDto>> Create([FromBody] CreateCampusDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var responseDto = await _handler.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = responseDto.Id }, responseDto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCampusDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var success = await _handler.UpdateAsync(id, request, cancellationToken);
        if (!success) return NotFound(new { message = $"Campus with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpPatch("{id:guid}/location")]
    public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateLocationDto request, CancellationToken cancellationToken)
    {
        var success = await _handler.UpdateLocationAsync(id, request, cancellationToken);
        if (!success) return NotFound(new { message = $"Campus with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var success = await _handler.DeleteAsync(id, cancellationToken);
        if (!success) return NotFound(new { message = $"Campus with ID '{id}' was not found." });

        return NoContent();
    }
}
