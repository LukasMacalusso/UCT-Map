using Incident.Domain.Entities;

namespace Incident.Domain.Queries;

public sealed record TicketSearchCriteria(
    Guid? UserRefId,
    Guid? StructureRefId,
    Tickets? Type,
    bool? IsActive,
    TicketSortBy SortBy,
    GeoPoint? Location,
    string? LostObjectId,
    ComplaintSearchCriteria? ComplaintDetails,
    bool Descending,
    int Page,
    int PageSize
);

public enum TicketSortBy { ReportedAt, Status }

public sealed record ComplaintSearchCriteria(
    string? Title,
    string? Description,
    Complainenum? Status);
