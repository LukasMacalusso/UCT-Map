using ErrorOr;
using Incident.Application.DTOs;
using System.Threading.Tasks;
using Incident.Domain.Entities;
using Incident.Domain.Queries;
namespace Incident.Application.Handlers;

public interface IReportHandler
{
    Task<ErrorOr<string>> CreateReportAsync(CreateReportRequest request);
    Task<ErrorOr<TicketResponse>> GetByIdAsync(string id);
    Task<ErrorOr<Success>> UpdateStatusTicketAsync(string id, UpdateStatusReport status);
    Task<ErrorOr<Success>> UpdateStatusComplainAsync(int? status, Ticket ticket);
    Task<ErrorOr<TicketPageResponse>> SearchAsync(TicketSearchRequest request, CancellationToken ct);
}
