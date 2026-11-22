using ErrorOr;
using Microsoft.AspNetCore.Mvc;

namespace Schedule.API.Common;

public static class ErrorResults
{
    public const string MissingUserMessage = "A valid token with the user id is required.";

    public static ActionResult ToActionResult(this ControllerBase controller, Error error)
    {
        var body = new { message = error.Description };
        return error.Type switch
        {
            ErrorType.NotFound => controller.NotFound(body),
            ErrorType.Forbidden => controller.StatusCode(StatusCodes.Status403Forbidden, body),
            ErrorType.Conflict => controller.Conflict(body),
            _ => controller.BadRequest(body)
        };
    }
}
