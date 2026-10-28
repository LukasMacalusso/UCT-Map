using ErrorOr;
using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Domain.Queries;
using System.Threading.Tasks;
using System;
using System.Linq;

namespace Incident.Application.Handlers;

public class LostObjectHandler : ILostObjectHandler
{
    private readonly ILostObjectRepository _lostObjectRepository;

    public LostObjectHandler(ILostObjectRepository lostObjectRepository)
    {
        _lostObjectRepository = lostObjectRepository;
    }

    public async Task<ErrorOr<string>> CreateObjectAsync(CreateLostObjectRequest request)
    {
        if (!string.IsNullOrWhiteSpace(request.PhotoUrl))
        {
            if (!Uri.TryCreate(request.PhotoUrl, UriKind.Absolute, out var uriResult) ||
                (uriResult.Scheme != Uri.UriSchemeHttp && uriResult.Scheme != Uri.UriSchemeHttps)) return Error.Validation("LostObject.PhotoUrl", "Invalid Photo URL format.");
        }

        if (request.StructureId == Guid.Empty) return Error.Validation("LostObject.StructureId", "Structure ID is required.");

        var lostObject = new LostObject
        {
            Title = request.Title,
            Description = request.Description,
            Status = (Objectenum)request.Status,
            ReportedAt = DateTime.UtcNow,
            PhotoUrl = request.PhotoUrl,
            StructureRefId = request.StructureId
        };

        await _lostObjectRepository.CreateAsync(lostObject);

        return lostObject.Id ?? string.Empty;
    }

    public async Task<ErrorOr<Success>> UpdateStatusAsync(string id, UpdateStatus status)
    {
        if (!Enum.IsDefined(typeof(Objectenum), status.Status)) return Error.Validation(
                code: "LostObject.Validation",
                description: $"Invalid status '{status.Status}'"
            );

        var lostObject = await _lostObjectRepository.GetByIdAsync(id);
        if (lostObject is null) return Error.NotFound(
                code: "LostObject.NotFound",
                description: $"LostObject with ID '{id}' was not found."
            );

        var response = await _lostObjectRepository.UpdateStatusAsync(lostObject, status.Status);

        if (!response) return Error.Failure(
                code: "LostObject.UpdateFailed",
                description: $"Failed to update status for LostObject with ID '{id}'."
            );

        return Result.Success;
    }

    public async Task<ErrorOr<LostObjectResponse>> GetByIdAsync(string id)
    {
        var lostObject = await _lostObjectRepository.GetByIdAsync(id);

        if (lostObject is null) return Error.NotFound(
                code: "LostObject.NotFound",
                description: "LostObject with ID '{id}' not found."
            );

        return new LostObjectResponse(
            Title: lostObject.Title,
            Description: lostObject.Description,
            Date: lostObject.ReportedAt.ToString(),
            Status: Enum.GetName(typeof(Objectenum), lostObject.Status)!,
            PhotoUrl: lostObject.PhotoUrl!,
            StructureId: lostObject.StructureRefId
        );
    }

    public async Task<ErrorOr<LostObjectPageResponse>> SearchAsync(LostObjectSearchRequest request, CancellationToken ct)
    {
        if (request.Status is not null && !Enum.IsDefined(typeof(Objectenum), request.Status.Value))
            return Error.Validation("LostObject.Status", $"Invalid status '{request.Status}'.");

        var criteria = new LostObjectSearchCriteria(
            Title: string.IsNullOrWhiteSpace(request.Title) ? null : request.Title.Trim(),
            StructureId: request.StructureId,
            Status: request.Status is { } s ? (Objectenum)s : null,
            SortBy: request.SortBy,
            Descending: request.Descending,
            Page: Math.Max(request.Page, 1),
            PageSize: Math.Clamp(request.PageSize, 1, 10));

        var result = await _lostObjectRepository.SearchAsync(criteria, ct);

        var items = result.Items.Select(lo => new LostObjectResponse(
                Title: lo.Title,
                Description: lo.Description,
                Date: lo.ReportedAt.ToString(),
                Status: lo.Status.ToString(),
                PhotoUrl: lo.PhotoUrl!,
                StructureId: lo.StructureRefId))
            .ToList();

        return new LostObjectPageResponse(items, result.TotalCount, criteria.Page, criteria.PageSize);
    }
    public async Task<ErrorOr<Success>> DeleteAsync(string id)
    {
        var lostObject = await _lostObjectRepository.GetByIdAsync(id);
        if (lostObject is null) return Error.NotFound(
                code: "LostObject.NotFound",
                description: $"LostObject with ID '{id}' was not found."
            );

        var response = await _lostObjectRepository.DeleteAsync(lostObject.Id!);

        if (!response) return Error.Failure(
                code: "LostObject.UpdateFailed",
                description: $"Failed to update status for LostObject with ID '{id}'."
            );

        return Result.Success;
    }
}
