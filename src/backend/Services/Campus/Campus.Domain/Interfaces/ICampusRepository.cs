using System;
using System.Threading;
using System.Threading.Tasks;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.Domain.Interfaces;

public interface ICampusRepository : IGenericRepository<CampusEntity>
{
    Task<CampusEntity?> GetByIdWithMapDataAsync(Guid id, CancellationToken cancellationToken = default);
}
