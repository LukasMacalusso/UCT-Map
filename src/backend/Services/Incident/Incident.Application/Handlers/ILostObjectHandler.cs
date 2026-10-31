using ErrorOr;
using Incident.Application.DTOs;
using Incident.Domain.Entities;
using System.Threading.Tasks;
using Incident.Domain.Queries;
namespace Incident.Application.Handlers;

public interface ILostObjectHandler
{
    Task<ErrorOr<string>> CreateObjectAsync(CreateLostObjectRequest request);
    Task<ErrorOr<LostObjectResponse>> GetByIdAsync(string id);
    Task<ErrorOr<Success>> UpdateStatusAsync(string id, UpdateStatus status);
    Task<ErrorOr<LostObjectPageResponse>> SearchAsync(LostObjectSearchRequest request, CancellationToken ct);
    Task<ErrorOr<Success>> DeleteAsync(string id, string userRefRole);
}
