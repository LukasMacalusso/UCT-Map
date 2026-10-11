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
        var buildings = await _handler.GetAllAsync(campusId, cancellationToken);
        return Ok(buildings);
    }

    [HttpGet("locations")]
    public async Task<ActionResult<IEnumerable<BuildingLocationDto>>> GetLocations([FromQuery] Guid? campusId, CancellationToken cancellationToken)
    {
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
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is required." });

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
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is required." });

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

