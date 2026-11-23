using Incident.Domain.Entities;
namespace Incident.Domain.Queries;

public sealed record LostObjectSearchCriteria(
    string? Title,
    Guid? StructureId,
    Objectenum? Status,
    LostObjectSortField SortBy,
    bool Descending,
    int Page,
    int PageSize);

public enum LostObjectSortField { ReportedAt, Title, Status }

public sealed record PagedResult<T>(IReadOnlyList<T> Items, long TotalCount, int Page, int PageSize);
