using Microsoft.AspNetCore.Mvc;
using Campus.Application.DTOs;
using Campus.Application.Handlers;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using System;

namespace Campus.API.Controllers;

[ApiController]
[Route("api/campus/category-groups")]
public class CategoryGroupController : ControllerBase
{
    private readonly CategoryGroupHandler _handler;

    public CategoryGroupController(CategoryGroupHandler handler)
    {
        _handler = handler;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryGroupDto>>> GetAll(CancellationToken cancellationToken)
    {
        var groups = await _handler.GetAllAsync(cancellationToken);
        return Ok(groups);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CategoryGroupDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        var dto = await _handler.GetByIdAsync(id, cancellationToken);
        if (dto is null) return NotFound(new { message = $"CategoryGroup with ID '{id}' was not found." });
        return Ok(dto);
    }

    [HttpPost]
    public async Task<ActionResult<CategoryGroupDto>> Create([FromBody] CreateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var dto = await _handler.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCategoryGroupDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Name)) return BadRequest(new { message = "Name is mandatory." });

        var success = await _handler.UpdateAsync(id, request, cancellationToken);
        if (!success) return NotFound(new { message = $"CategoryGroup with ID '{id}' was not found." });

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var success = await _handler.DeleteAsync(id, cancellationToken);
        if (!success) return NotFound(new { message = $"CategoryGroup with ID '{id}' was not found." });

        return NoContent();
    }
}
