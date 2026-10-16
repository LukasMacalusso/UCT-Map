
using Incident.Domain.Entities;
using Incident.Domain.Queries;
namespace Incident.Application.DTOs;

public record CreateLostObjectRequest(
    string Title,
    string Description,
    int Status,
    string PhotoUrl,
    Guid StructureId
);

public record LostObjectSearchRequest(
    string? Title = null,
    Guid? StructureId = null,
    int? Status = null,
    LostObjectSortField SortBy = LostObjectSortField.ReportedAt,
    bool Descending = true,
    int Page = 1,
    int PageSize = 10);

public record UpdateStatus(int Status);
