using Incident.Domain.Entities;
using Incident.Domain.Queries;
namespace Incident.Domain.Interfaces;

public interface ILostObjectRepository : IRepository<LostObject>
{
    Task<bool> UpdateStatusAsync(LostObject lostObject, int status);
    Task<PagedResult<LostObject>> SearchAsync(LostObjectSearchCriteria c, CancellationToken ct);
}
