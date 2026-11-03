using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using ErrorOr;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Campus.API.Controllers;

[ApiController]
[Route("api/campus/categories")]
public class CategoryController : ControllerBase
{
    private readonly CategoryHandler _handler;

    public CategoryController(CategoryHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryDto>>> GetAll(CancellationToken cancellationToken)
    {
        var categories = await _handler.GetAllAsync(cancellationToken);
        return Ok(categories);
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
    public async Task<IActionResult> Create([FromBody] CreateCategoryDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (string.IsNullOrWhiteSpace(request.Icon)) return BadRequest(new { message = "Icon is mandatory." });
        if (request.Icon.Length > 100) return BadRequest(new { message = "Icon cannot exceed 100 characters." });
        if (request.Description != null && request.Description.Length > 250) return BadRequest(new { message = "Description cannot exceed 250 characters." });

        var result = await _handler.CreateAsync(request, cancellationToken);
        return result.Match(
            dto => CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto),
            errors => Problem(statusCode: StatusCodes.Status400BadRequest, title: errors.First().Description)
        );
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCategoryDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });
        if (request.Name.Length > 100) return BadRequest(new { message = "Name cannot exceed 100 characters." });
        if (string.IsNullOrWhiteSpace(request.Icon)) return BadRequest(new { message = "Icon is mandatory." });
        if (request.Icon.Length > 100) return BadRequest(new { message = "Icon cannot exceed 100 characters." });
        if (request.Description != null && request.Description.Length > 250) return BadRequest(new { message = "Description cannot exceed 250 characters." });

        var result = await _handler.UpdateAsync(id, request, cancellationToken);
        return result.Match(
            _ => (IActionResult)NoContent(),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type == ErrorType.NotFound ? StatusCodes.Status404NotFound : StatusCodes.Status400BadRequest;
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }

    [HttpPut("reorder")]
    public async Task<IActionResult> Reorder([FromBody] IEnumerable<ReorderItemDto> items, CancellationToken cancellationToken)
    {
        if (items is null || !items.Any()) return BadRequest(new { message = "The items list cannot be empty." });

        var result = await _handler.ReorderAsync(items, cancellationToken);
        return result.Match(
            _ => (IActionResult)NoContent(),
            errors => Problem(statusCode: StatusCodes.Status400BadRequest, title: errors.First().Description)
        );
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var result = await _handler.DeleteAsync(id, cancellationToken);
        return result.Match(
            _ => (IActionResult)NoContent(),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type == ErrorType.Conflict ? StatusCodes.Status409Conflict : StatusCodes.Status404NotFound;
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }
}
