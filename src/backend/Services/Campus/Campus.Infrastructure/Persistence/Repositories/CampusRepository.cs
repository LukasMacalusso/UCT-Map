using System;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.Infrastructure.Persistence.Repositories;

public class CampusRepository : GenericRepository<CampusEntity>, ICampusRepository
{
    public CampusRepository(CampusDbContext context) : base(context)
    {
    }

    public async Task<CampusEntity?> GetByIdWithMapDataAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await Context.Campuses
            .AsNoTracking()
            .AsSplitQuery()
            .Include(c => c.Buildings)
            .Include(c => c.Structures)
                .ThenInclude(s => s.Category)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
    }
}
