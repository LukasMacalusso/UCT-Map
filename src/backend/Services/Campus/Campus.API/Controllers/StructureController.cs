using Microsoft.AspNetCore.Mvc;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;

namespace Campus.API.Controllers;

[ApiController]
[Route("api/campus/structures")]
public class StructureController : ControllerBase
{
    private readonly StructureHandler _handler;

    public StructureController(StructureHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<StructureDto>>> GetAll([FromQuery] Guid? campusId, [FromQuery] Guid? categoryId, CancellationToken cancellationToken)
    {
        if (campusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' query parameter cannot be empty." });
        if (categoryId == Guid.Empty) return BadRequest(new { message = "The 'categoryId' query parameter cannot be empty." });

        var structures = await _handler.GetAllAsync(campusId, categoryId, cancellationToken);
        return Ok(structures);
    }

    [HttpGet("locations")]
    public async Task<ActionResult<IEnumerable<StructureLocationDto>>> GetLocations([FromQuery] Guid? campusId, [FromQuery] Guid? categoryId, CancellationToken cancellationToken)
    {
        if (campusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' query parameter cannot be empty." });
        if (categoryId == Guid.Empty) return BadRequest(new { message = "The 'categoryId' query parameter cannot be empty." });

        var structures = await _handler.GetAllLocationsAsync(campusId, categoryId, cancellationToken);
        return Ok(structures);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<StructureDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var dto = await _handler.GetByIdAsync(id, cancellationToken);
        if (dto is null) return NotFound(new { message = $"Structure with ID '{id}' was not found." });
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<StructureDto>> Create([FromBody] CreateStructureDto request, CancellationToken cancellationToken)
    {
        if (request.CampusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' parameter cannot be empty." });
        if (request.CategoryId == Guid.Empty) return BadRequest(new { message = "The 'categoryId' parameter cannot be empty." });
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is Required." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });

        var (dto, error) = await _handler.CreateAsync(request, cancellationToken);
        if (error != null) return BadRequest(new { message = error });

        return CreatedAtAction(nameof(GetById), new { id = dto!.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateStructureDto request, CancellationToken cancellationToken)
    {
        if (request.CampusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' parameter cannot be empty." });
        if (request.CategoryId == Guid.Empty) return BadRequest(new { message = "The 'categoryId' parameter cannot be empty." });
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is Required." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });

        var (success, error) = await _handler.UpdateAsync(id, request, cancellationToken);
        if (error != null) return BadRequest(new { message = error });
        if (!success) return NotFound();

        return NoContent();
    }

    [HttpPatch("{id:guid}/location")]
    public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateLocationDto request, CancellationToken cancellationToken)
    {
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });

        var success = await _handler.UpdateLocationAsync(id, request, cancellationToken);
        if (!success) return NotFound(new { message = $"Structure with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var success = await _handler.DeleteAsync(id, cancellationToken);
        if (!success) return NotFound(new { message = $"Structure with ID '{id}' was not found." });

        return NoContent();
    }
}
