using Microsoft.AspNetCore.Mvc;
using Yarp.ReverseProxy.Forwarder;

namespace ApiGateway.API.Middlewares;

public class GlobalErrorHandlingMiddleware(
    RequestDelegate next,
    ILogger<GlobalErrorHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception exception)
        {
            logger.LogError(exception, "Unhandled exception occurred in API Gateway for {Path}", context.Request.Path);
            if (context.Response.HasStarted) throw;
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        }

        if (!context.Response.HasStarted && context.Response.StatusCode >= StatusCodes.Status400BadRequest)
        {
            await WriteProblemDetailsAsync(context);
        }
    }

    private static async Task WriteProblemDetailsAsync(HttpContext context)
    {
        var forwarderError = context.Features.Get<IForwarderErrorFeature>();
        var statusCode = MapStatusCode(context.Response.StatusCode, forwarderError?.Error);
        var (title, detail) = GetErrorMetadata(statusCode, forwarderError?.Error);

        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        var problemDetails = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };

        await context.Response.WriteAsJsonAsync(problemDetails);
    }

    private static int MapStatusCode(int currentStatusCode, ForwarderError? forwarderError) => forwarderError switch
    {
        ForwarderError.RequestTimedOut => StatusCodes.Status504GatewayTimeout,
        ForwarderError.NoAvailableDestinations => StatusCodes.Status503ServiceUnavailable,
        not null => StatusCodes.Status502BadGateway,
        null => currentStatusCode
    };

    private static (string Title, string Detail) GetErrorMetadata(int statusCode, ForwarderError? forwarderError)
    {
        if (forwarderError is not null)
        {
            return statusCode switch
            {
                StatusCodes.Status504GatewayTimeout => ("Gateway Timeout", "The downstream microservice timed out while processing the request."),
                StatusCodes.Status503ServiceUnavailable => ("Service Unavailable", "No healthy downstream microservice destinations are available."),
                _ => ("Bad Gateway", "The downstream microservice could not be reached or returned an invalid response.")
            };
        }

        return statusCode switch
        {
            StatusCodes.Status401Unauthorized => ("Unauthorized", "Authentication is required or the provided token is invalid."),
            StatusCodes.Status403Forbidden => ("Forbidden", "You do not have permission to access this resource."),
            StatusCodes.Status404NotFound => ("Not Found", "The requested gateway route does not exist."),
            _ => ("Internal Server Error", "An unexpected error occurred in the API Gateway.")
        };
    }
}
