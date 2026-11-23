using Incident.Domain.Entities;
using System;

namespace Incident.Application.DTOs;

public record TicketResponse(
    string Id,
    Guid UserRefId,
    Guid? StructureRefId,
    Tickets TicketType,
    bool IsActive,
    DateTime ReportedAt,
    ComplaintDetails? ComplaintDetails = null,
    string? LostObjectId = null);

public record TicketPageResponse(
    IReadOnlyList<TicketResponse> Items,
    long TotalCount,
    int Page,
    int PageSize)
{
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
}

