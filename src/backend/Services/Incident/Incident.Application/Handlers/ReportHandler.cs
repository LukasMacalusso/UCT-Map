using ErrorOr;
using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Application.Handlers;
using Incident.Application.Common;
using System.Threading.Tasks;
using System;
using System.Linq;
using Incident.Domain.Queries;

namespace Incident.Application.Handlers;

public class ReportHandler : IReportHandler
{
    private readonly ITicketRepository _ticketRepository;

    private readonly ILostObjectRepository _lostobjectRepository;

    public ReportHandler(ITicketRepository ticketRepository, ILostObjectRepository lostObjectRepository)
    {
        _ticketRepository = ticketRepository;
        _lostobjectRepository = lostObjectRepository;
    }

    public async Task<ErrorOr<string>> CreateReportAsync(CreateReportRequest request)
    {
        if (request.UserRefId == Guid.Empty) return Error.Validation("Report.UserRefId", "User ID is required.");

        if (request.StructureRefId == Guid.Empty) return Error.Validation("Report.StructureRefId", "Structure ID is required.");

        if (!Enum.IsDefined(typeof(Tickets), request.TicketType)) return Error.Validation(
                code: "Ticket.Validation",
                description: $"Invalid status '{request.TicketType}'"
            );

        if (request.LostObjectId is not null)
        {
            var lostObject = await _lostobjectRepository.GetByIdAsync(request.LostObjectId);
            if (lostObject is null) return Error.NotFound(
                    code: "LostObject.NotFound",
                    description: $"LostObject with ID '{request.LostObjectId}' not found."
                );
        }

        var ticket = new Ticket
        {
            UserRefId = request.UserRefId,
            StructureRefId = request.StructureRefId,
            TicketType = (Tickets)request.TicketType,
            IsActive = request.IsActive,
            ReportedAt = request.ReportedAt,
            ComplaintDetails = request.Complaint,
            LostObjectId = request.LostObjectId
        };

        await _ticketRepository.CreateAsync(ticket);

        return ticket.Id ?? string.Empty;
    }

    public async Task<ErrorOr<TicketResponse>> GetByIdAsync(string id)
    {
        var ticket = await _ticketRepository.GetByIdAsync(id);
        if (ticket is null) return Error.NotFound(
                code: "Report.NotFound",
                description: $"Report with ID '{id}'"
            );

        return new TicketResponse(
            ticket.Id!,
            ticket.UserRefId,
            ticket.StructureRefId,
            (Tickets)ticket.TicketType,
            ticket.IsActive,
            ticket.ReportedAt,
            ticket.ComplaintDetails,
            ticket.LostObjectId
        );
    }
    public async Task<ErrorOr<Success>> UpdateStatusTicketAsync(string id, UpdateStatusReport Update)
    {
        if (!Enum.IsDefined(typeof(Tickets), Update.Status)) return Error.Validation(
                code: "Ticket.Validation",
                description: $"Invalid status '{Update.Status}'"
            );

        var ticket = await _ticketRepository.GetByIdAsync(id);
        if (ticket is null) return Error.NotFound(
                code: "Ticket.NotFound",
                description: $"Ticket with ID '{id}' was not found."
            );

        var response = await _ticketRepository.UpdateStatusAsync(ticket, Update.Status);
        bool complainUpdate = false;

        if (Update.ComplainStatus is not null && ticket.ComplaintDetails is not null)
        {
            var responseComplaint = await UpdateStatusComplainAsync(Update.ComplainStatus, ticket);
            complainUpdate = !responseComplaint.IsError;
        }
        ;
        if (!response && !complainUpdate) return Error.Failure(
                code: "Ticket.UpdateFailed",
                description: $"Failed to update status for Ticket with ID '{id}'."
            );

        return Result.Success;
    }
    public async Task<ErrorOr<Success>> UpdateStatusComplainAsync(int? status, Ticket ticket)
    {
        if (!Enum.IsDefined(typeof(Complainenum), status!)) return Error.Validation(
                code: "Ticket.Validation",
                description: $"Invalid status '{status}'"
        );


        var response = await _ticketRepository.UpdateStatusComplainAsync(ticket, status);

        if (!response) return Error.Failure(
                code: "Ticket.UpdateFailed",
                description: $"Failed to update status for Ticket complain with ID '{ticket.Id}'."
            );
        return Result.Success;
    }

    public async Task<ErrorOr<TicketPageResponse>> SearchAsync(TicketSearchRequest request, CancellationToken ct)
    {
        if (request.Type is not null && !Enum.IsDefined(typeof(Tickets), request.Type.Value))
            return Error.Validation(
                code: "Ticket.Type",
                description: $"Invalid type '{request.Type}'."
            );

        if (request.ComplaintDetails?.Status is { } complaintStatus &&
            !Enum.IsDefined(typeof(Complainenum), complaintStatus))
            return Error.Validation(
                code: "Ticket.ComplaintStatus",
                description: $"Invalid complaint status '{complaintStatus}'."
            );

        var criteria = new TicketSearchCriteria(
            UserRefId: request.UserRefId,
            StructureRefId: request.StructureRefId,
            Type: request.Type is { } t ? (Tickets)t : null,
            IsActive: request.IsActive,
            SortBy: request.SortBy,
            Location: request.Location,
            LostObjectId: string.IsNullOrWhiteSpace(request.LostObjectId) ? null : request.LostObjectId.Trim(),
            ComplaintDetails: ComplaintCriteria(request.ComplaintDetails),
            Descending: request.Descending,
            Page: Math.Max(request.Page, 1),
            PageSize: Math.Clamp(request.PageSize, 1, 10));

        var result = await _ticketRepository.SearchAsync(criteria, ct);

        var items = result.Items.Select(ticket => new TicketResponse(
                Id: ticket.Id!,
                UserRefId: ticket.UserRefId,
                StructureRefId: ticket.StructureRefId,
                TicketType: ticket.TicketType,
                IsActive: ticket.IsActive,
                ReportedAt: ticket.ReportedAt,
                ComplaintDetails: ticket.ComplaintDetails,
                LostObjectId: ticket.LostObjectId))
            .ToList();

        return new TicketPageResponse(items, result.TotalCount, criteria.Page, criteria.PageSize);
    }


    private static ComplaintSearchCriteria? ComplaintCriteria(ComplaintSearchRequest? request)
    {
        if (request is null) return null;

        var title = string.IsNullOrWhiteSpace(request.Title) ? null : request.Title.Trim();
        var description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        var status = request.Status is { } s ? (Complainenum?)s : null;

        if (title is null && description is null && status is null) return null;

        return new ComplaintSearchCriteria(title, description, status);
    }
    public async Task<ErrorOr<Success>> DeleteAsync(string id, string userRefRole, string userRefId)
    {
        var lostObject = await _ticketRepository.GetByIdAsync(id);
        if (lostObject is null) return Error.NotFound(
                code: "LostObject.NotFound",
                description: $"LostObject with ID '{id}' was not found."
            );

        if (userRefId != lostObject.UserRefId.ToString()) {
            if (userRefRole is not ("Admin" or "ObjectsOfficer" or "ComplaintsOfficer"))
            {
                return Error.Unauthorized(
                        code: "LostObject.Unauthorized",
                        description: $"'{userRefRole}' is not authorized"
                    );
            }
        }
        var response = await _ticketRepository.DeleteAsync(lostObject.Id!);

        if (!response) return Error.Failure(
                code: "LostObject.UpdateFailed",
                description: $"Failed to update status for LostObject with ID '{id}'."
            );

        return Result.Success;
    }
}
