using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using Incident.Domain.Queries;
using Incident.Infrastructure.Persistence;
using Incident.Infrastructure.Persistence.Search;
using MongoDB.Driver;

namespace Incident.Infrastructure.Persistence.Repositories;

public class TicketRepository : MongoRepository<Ticket>, ITicketRepository
{
    public TicketRepository(IMongoDbContext context)
        : base(context, "tickets")
    { }
    public async Task<bool> UpdateStatusAsync(Ticket ticket, int status)
    {
        var filter = Builders<Ticket>.Filter.Eq(x => x.Id, ticket.Id);

        var update = Builders<Ticket>.Update.Set(t => t.TicketType, (Tickets)status);

        var result = await _collection.UpdateOneAsync(filter, update);

        return result.ModifiedCount > 0;
    }
    public async Task<bool> UpdateStatusComplainAsync(Ticket ticket, int? status)
    {
        var filter = Builders<Ticket>.Filter.Eq(t => t.Id, ticket.Id);

        var update = Builders<Ticket>.Update
            .Set(t => t.ComplaintDetails!.Status, (Complainenum)status!);

        var result = await _collection.UpdateOneAsync(
            filter,
            update
        );

        return result.ModifiedCount > 0;
    }

    public async Task<PagedResult<Ticket>> SearchAsync(TicketSearchCriteria c, CancellationToken ct)
    {
        var filter = TicketFilters.Build(c);
        var sort = TicketFilters.Sort(c.SortBy, c.Descending);

        var total = await _collection.CountDocumentsAsync(filter, cancellationToken: ct);

        var items = await _collection.Find(filter)
            .Sort(sort)
            .Skip((c.Page - 1) * c.PageSize)
            .Limit(c.PageSize)
            .ToListAsync(ct);

        return new PagedResult<Ticket>(items, total, c.Page, c.PageSize);
    }
}
