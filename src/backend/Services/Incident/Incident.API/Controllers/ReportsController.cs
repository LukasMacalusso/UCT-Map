using Incident.Application.DTOs;
using Incident.Application.Handlers;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.AspNetCore.Http;
using Incident.Application.Common;
using ErrorOr;
namespace Incident.API.Controllers;

[ApiController]
[Route("api/incident/reports")]
public class ReportsController : ControllerBase
{
    private readonly IReportHandler _reportHandler;

    public ReportsController(IReportHandler reportHandler)
    {
        _reportHandler = reportHandler;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateReportRequest request)
    {
        var userRefId = JwtUserIdReader.GetUserIdToken(Request.Headers.Authorization.ToString());
        if (userRefId is null)
            return Unauthorized();

        request = request with { UserRefId = userRefId.Value };

        var result = await _reportHandler.CreateReportAsync(request);

        return result.Match(
            id => CreatedAtAction(nameof(GetById), new { id }, new { id }),
            errors => Problem(statusCode: StatusCodes.Status400BadRequest, title: errors.First().Description)
        );
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id)
    {
        var result = await _reportHandler.GetByIdAsync(id);
        return result.Match(
            ticket => Ok(ticket),
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

    [HttpPatch("{id}/report/status")]
    public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateStatusReport Update)
    {
        var result = await _reportHandler.UpdateStatusTicketAsync(id.ToString(), Update);
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
}
