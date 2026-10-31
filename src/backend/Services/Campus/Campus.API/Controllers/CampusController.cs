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

    [HttpGet("{id:guid}/map")]
    public async Task<ActionResult<CampusMapDto>> GetMap(Guid id, CancellationToken cancellationToken)
    {
        if (id == Guid.Empty) return BadRequest(new { message = "The 'id' parameter cannot be empty." });

        var dto = await _handler.GetMapByIdAsync(id, cancellationToken);
        if (dto is null) return NotFound(new { message = $"Campus with ID '{id}' was not found." });
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<CampusDto>> Create([FromBody] CreateCampusDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (string.IsNullOrWhiteSpace(request.Address)) return BadRequest(new { message = "Address is mandatory." });
        if (request.Address.Length > 100) return BadRequest(new { message = "Address cannot exceed 100 characters." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });
        if (request.Zoom < 0 || request.Zoom > 22 || request.Pitch < 0 || request.Pitch > 85 || request.Bearing < -180 || request.Bearing > 180)
            return BadRequest(new { message = "Camera parameters out of valid range." });

        var responseDto = await _handler.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = responseDto.Id }, responseDto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCampusDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (string.IsNullOrWhiteSpace(request.Address)) return BadRequest(new { message = "Address is mandatory." });
        if (request.Address.Length > 100) return BadRequest(new { message = "Address cannot exceed 100 characters." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });
        if (request.Zoom < 0 || request.Zoom > 22 || request.Pitch < 0 || request.Pitch > 85 || request.Bearing < -180 || request.Bearing > 180)
            return BadRequest(new { message = "Camera parameters out of valid range." });

        var success = await _handler.UpdateAsync(id, request, cancellationToken);
        if (!success) return NotFound(new { message = $"Campus with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpPatch("{id:guid}/location")]
    public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateLocationDto request, CancellationToken cancellationToken)
    {
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });

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
