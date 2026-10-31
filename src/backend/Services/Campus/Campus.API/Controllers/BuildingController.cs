using Microsoft.AspNetCore.Mvc;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;
using System.Linq;
using Microsoft.AspNetCore.Http;
using ErrorOr;

namespace Campus.API.Controllers;

[ApiController]
[Route("api/campus/buildings")]
public class BuildingController : ControllerBase
{
    private readonly BuildingHandler _handler;

    public BuildingController(BuildingHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<BuildingDto>>> GetAll([FromQuery] Guid? campusId, CancellationToken cancellationToken)
    {
        if (campusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' query parameter cannot be empty." });

        var buildings = await _handler.GetAllAsync(campusId, cancellationToken);
        return Ok(buildings);
    }

    [HttpGet("locations")]
    public async Task<ActionResult<IEnumerable<BuildingLocationDto>>> GetLocations([FromQuery] Guid? campusId, CancellationToken cancellationToken)
    {
        if (campusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' query parameter cannot be empty." });

        var buildings = await _handler.GetAllLocationsAsync(campusId, cancellationToken);
        return Ok(buildings);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _handler.GetByIdAsync(id, cancellationToken);
        return result.Match(
            dto => Ok(dto),
            errors => Problem(statusCode: StatusCodes.Status404NotFound, title: errors.First().Description)
        );
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBuildingDto request, CancellationToken cancellationToken)
    {
        if (request.CampusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' parameter cannot be empty." });
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is required." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (request.FloorsCount < 1) return BadRequest(new { message = "FloorsCount must be at least 1." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });
        if (request.OpenTime.HasValue && request.CloseTime.HasValue && request.OpenTime >= request.CloseTime)
            return BadRequest(new { message = "OpenTime must be earlier than CloseTime." });
        if (request.Services != null && request.Services.Length > 150)
            return BadRequest(new { message = "Services cannot exceed 150 characters." });

        var result = await _handler.CreateAsync(request, cancellationToken);

        return result.Match(
            dto => CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type == ErrorType.NotFound ? StatusCodes.Status404NotFound : StatusCodes.Status400BadRequest;
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateBuildingDto request, CancellationToken cancellationToken)
    {
        if (request.CampusId == Guid.Empty) return BadRequest(new { message = "The 'campusId' parameter cannot be empty." });
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is required." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (request.FloorsCount < 1) return BadRequest(new { message = "FloorsCount must be at least 1." });
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });
        if (request.OpenTime.HasValue && request.CloseTime.HasValue && request.OpenTime >= request.CloseTime)
            return BadRequest(new { message = "OpenTime must be earlier than CloseTime." });
        if (request.Services != null && request.Services.Length > 150)
            return BadRequest(new { message = "Services cannot exceed 150 characters." });

        var result = await _handler.UpdateAsync(id, request, cancellationToken);

        return result.Match(
            success => (IActionResult)NoContent(),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type == ErrorType.NotFound ? StatusCodes.Status404NotFound : StatusCodes.Status400BadRequest;
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }

    [HttpPatch("{id:guid}/location")]
    public async Task<IActionResult> UpdateLocation(Guid id, [FromBody] UpdateLocationDto request, CancellationToken cancellationToken)
    {
        if (request.Latitude < -90.0 || request.Latitude > 90.0 || request.Longitude < -180.0 || request.Longitude > 180.0)
            return BadRequest(new { message = "Coordinates out of valid range." });

        var result = await _handler.UpdateLocationAsync(id, request, cancellationToken);

        return result.Match(
            success => (IActionResult)NoContent(),
            errors => Problem(statusCode: StatusCodes.Status404NotFound, title: errors.First().Description)
        );
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var result = await _handler.DeleteAsync(id, cancellationToken);

        return result.Match(
            success => (IActionResult)NoContent(),
            errors => Problem(statusCode: StatusCodes.Status404NotFound, title: errors.First().Description)
        );
    }
}

