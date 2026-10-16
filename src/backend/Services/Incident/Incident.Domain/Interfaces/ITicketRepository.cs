using Incident.Domain.Entities;
using Incident.Domain.Queries;
namespace Incident.Domain.Interfaces;

public interface ITicketRepository : IRepository<Ticket>
{
    Task<bool> UpdateStatusAsync(Ticket ticket, int status);
    Task<bool> UpdateStatusComplainAsync(Ticket ticket, int? status);
    Task<PagedResult<Ticket>> SearchAsync(TicketSearchCriteria c, CancellationToken ct);
}
