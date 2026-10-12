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
[Route("api/campus/rooms")]
public class RoomController : ControllerBase
{
    private readonly RoomHandler _handler;

    public RoomController(RoomHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<RoomDto>>> GetAll([FromQuery] Guid? buildingId, [FromQuery] Guid? categoryId, CancellationToken cancellationToken)
    {
        if (buildingId == Guid.Empty) return BadRequest(new { message = "The 'buildingId' query parameter cannot be empty." });
        if (categoryId == Guid.Empty) return BadRequest(new { message = "The 'categoryId' query parameter cannot be empty." });

        var rooms = await _handler.GetAllAsync(buildingId, categoryId, cancellationToken);
        return Ok(rooms);
    }

    [HttpGet("search")]
    public async Task<ActionResult<IEnumerable<RoomDto>>> Search([FromQuery] string term, CancellationToken cancellationToken)
    {
        var rooms = await _handler.SearchRoomsAsync(term ?? string.Empty, cancellationToken);
        return Ok(rooms);
    }

    [HttpGet("/api/campus/buildings/{buildingId:guid}/rooms")]
    public async Task<ActionResult<IEnumerable<RoomDto>>> GetByBuilding(Guid buildingId, CancellationToken cancellationToken)
    {
        var rooms = await _handler.GetRoomsByBuildingAsync(buildingId, cancellationToken);
        return Ok(rooms);
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
    public async Task<IActionResult> Create([FromBody] CreateRoomDto request, CancellationToken cancellationToken)
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
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateRoomDto request, CancellationToken cancellationToken)
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
