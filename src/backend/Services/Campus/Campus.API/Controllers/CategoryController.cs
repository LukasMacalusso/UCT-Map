using Microsoft.AspNetCore.Mvc;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;

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
    public async Task<ActionResult<CategoryDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var dto = await _handler.GetByIdAsync(id, cancellationToken);
        if (dto is null) return NotFound(new { message = $"Category with ID '{id}' was not found." });
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<CategoryDto>> Create([FromBody] CreateCategoryDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var (dto, error) = await _handler.CreateAsync(request, cancellationToken);
        if (error is not null) return BadRequest(new { message = error });

        return CreatedAtAction(nameof(GetById), new { id = dto!.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCategoryDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var (success, error) = await _handler.UpdateAsync(id, request, cancellationToken);
        if (error is not null) return BadRequest(new { message = error });
        if (!success) return NotFound(new { message = $"Category with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var success = await _handler.DeleteAsync(id, cancellationToken);
        if (!success) return NotFound(new { message = $"Category with ID '{id}' was not found." });

        return NoContent();
    }
}
