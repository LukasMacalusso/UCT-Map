
using Incident.Domain.Entities;

namespace Incident.Application.DTOs;

public record LostObjectResponse(
    string Title,
    string Description,
    string Date,
    string Status,
    string PhotoUrl,
    Guid StructureId // -> FindName
);

public record LostObjectPageResponse(
    IReadOnlyList<LostObjectResponse> Items,
    long TotalCount,
    int Page,
    int PageSize)
{
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
}
