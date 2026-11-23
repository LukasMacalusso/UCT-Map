
using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.Domain.Interfaces;
using Incident.Infrastructure.Persistence.Search;
using MongoDB.Driver;

namespace Incident.Infrastructure.Persistence.Repositories;

public class ObjectRepository : MongoRepository<LostObject>, ILostObjectRepository
{
    public ObjectRepository(IMongoDbContext context)
        : base(context, "lost_objects")
    { }

    public override async Task CreateAsync(LostObject entity)
    {
        await base.CreateAsync(entity);
    }

    public async Task<bool> UpdateStatusAsync(LostObject lostObject, int status)
    {
        lostObject.Status = (Objectenum)status;

        var filter = Builders<LostObject>.Filter.Eq(x => x.Id, lostObject.Id);
        var result = await _collection.ReplaceOneAsync(filter, lostObject);

        return result.ModifiedCount > 0;
    }
    public async Task<PagedResult<LostObject>> SearchAsync(LostObjectSearchCriteria c, CancellationToken ct)
    {
        var filter = LostObjectFilters.Build(c);
        var sort = LostObjectFilters.Sort(c.SortBy, c.Descending);

        var total = await _collection.CountDocumentsAsync(filter, cancellationToken: ct);

        var items = await _collection.Find(filter)
            .Sort(sort)
            .Skip((c.Page - 1) * c.PageSize)
            .Limit(c.PageSize)
            .ToListAsync(ct);

        return new PagedResult<LostObject>(items, total, c.Page, c.PageSize);
    }
}
