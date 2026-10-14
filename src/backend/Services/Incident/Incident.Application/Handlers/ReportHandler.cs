using ErrorOr;
using Incident.Application.DTOs;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Application.Handlers;
using Incident.Application.Common;
using System.Threading.Tasks;
using System;

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
            Console.WriteLine(request.LostObjectId);
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
}
