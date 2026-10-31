using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.AspNetCore.Http;
using Incident.Application.Common;
using ErrorOr;
using MongoDB.Bson;
namespace Incident.API.Controllers;

[ApiController]
[Route("api/incident/lost-objects")]
public class LostObjectsController : ControllerBase
{
    private readonly ILostObjectHandler _lostObjectHandler;

    public LostObjectsController(ILostObjectHandler lostObjectHandler)
    {
        _lostObjectHandler = lostObjectHandler;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateLostObjectRequest request)
    {
        var result = await _lostObjectHandler.CreateObjectAsync(request);

        return result.Match(
            id => CreatedAtAction(nameof(GetById), new { id }, new { id }),
            errors => Problem(statusCode: StatusCodes.Status400BadRequest, title: errors.First().Description)
        );
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var result = await _lostObjectHandler.GetByIdAsync(id);

        return result.Match(
            success => (IActionResult)NoContent(),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type switch
                {
                    ErrorType.NotFound => StatusCodes.Status404NotFound,
                    _ => StatusCodes.Status400BadRequest
                };
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }

    [HttpPatch("{id}/lost/status")]
    public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateStatus status)
    {
        var result = await _lostObjectHandler.UpdateStatusAsync(id.ToString(), status);
        return result.Match(
            success => (IActionResult)NoContent(),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type switch
                {
                    ErrorType.NotFound => StatusCodes.Status404NotFound,
                    _ => StatusCodes.Status400BadRequest
                };
                return Problem(statusCode: statusCode, title: firstError.Description);
            }
        );
    }
    [HttpGet]
    public async Task<IActionResult> Search([FromQuery] LostObjectSearchRequest request, CancellationToken ct)
    {
        var result = await _lostObjectHandler.SearchAsync(request, ct);
        return result.Match(
            page => Ok(page),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type switch
                {
                    ErrorType.NotFound => StatusCodes.Status404NotFound,
                    _ => StatusCodes.Status400BadRequest
                };
                return Problem(statusCode: statusCode, title: firstError.Description);
            });
    }
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete([FromRoute] string id)
    {
        var userRefRole = JwtUserIdReader.GetUserRoleToken(Request.Headers.Authorization.ToString());
        var result = await _lostObjectHandler.DeleteAsync(id, userRefRole!);
        return result.Match(
            page => Ok(page),
            errors =>
            {
                var firstError = errors.First();
                var statusCode = firstError.Type switch
                {
                    ErrorType.NotFound => StatusCodes.Status404NotFound,
                    _ => StatusCodes.Status400BadRequest
                };
                return Problem(statusCode: statusCode, title: firstError.Description);
            });
    }
}
