using System;
using Incident.Domain.Entities;
using Incident.Domain.Queries;

namespace Incident.Application.DTOs;

public record CreateReportRequest(
        Guid UserRefId,
        Guid StructureRefId,
        int TicketType,
        bool IsActive,
        DateTime ReportedAt,
        string? LostObjectId = null,
        ComplaintDetails? Complaint = null);

public record TicketSearchRequest(
    Guid? UserRefId = null,
    Guid? StructureRefId = null,
    int? Type = null,
    bool? IsActive = null,
    TicketSortBy SortBy = TicketSortBy.ReportedAt,
    GeoPoint? Location = null,
    string? LostObjectId = null,
    ComplaintSearchRequest? ComplaintDetails = null,
    bool Descending = true,
    int Page = 1,
    int PageSize = 10);

public record ComplaintSearchRequest(
    string? Title = null,
    string? Description = null,
    int? Status = null);

public record UpdateStatusReport(
    int Status,
    int? ComplainStatus = null
);
