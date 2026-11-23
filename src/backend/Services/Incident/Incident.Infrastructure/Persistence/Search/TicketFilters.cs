using System.Text.RegularExpressions;
using Incident.Domain.Entities;
using Incident.Domain.Queries;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Incident.Infrastructure.Persistence.Search;

internal static class TicketFilters
{
    private static readonly FilterDefinitionBuilder<Ticket> F = Builders<Ticket>.Filter;

    public static FilterDefinition<Ticket> Build(TicketSearchCriteria c)
    {
        var parts = new List<FilterDefinition<Ticket>>();

        if (c.UserRefId is { } u) parts.Add(ByUserRefId(u));
        if (c.StructureRefId is { } st) parts.Add(ByStructure(st));
        if (c.Type is { } t) parts.Add(ByType(t));
        if (c.IsActive is { } a) parts.Add(ByIsActive(a));
        if (c.LostObjectId is { } lo) parts.Add(ByLostObjectId(lo));
        if (c.Location is { } location) parts.Add(ByLocation(location));

        if (c.ComplaintDetails is { } complaint)
        {
            if (complaint.Title is not null) parts.Add(ByComplaintTitle(complaint.Title));
            if (complaint.Description is not null) parts.Add(ByComplaintDescription(complaint.Description));
            if (complaint.Status is { } cs) parts.Add(ByComplaintStatus(cs));
        }

        return parts.Count == 0 ? F.Empty : F.And(parts);
    }

    public static FilterDefinition<Ticket> ByUserRefId(Guid id)
        => F.Eq(x => x.UserRefId, id);

    public static FilterDefinition<Ticket> ByStructure(Guid id)
        => F.Eq(x => x.StructureRefId, id);

    public static FilterDefinition<Ticket> ByType(Tickets type)
        => F.Eq(x => x.TicketType, type);

    public static FilterDefinition<Ticket> ByIsActive(bool isActive)
        => F.Eq(x => x.IsActive, isActive);

    public static FilterDefinition<Ticket> ByLostObjectId(string id)
        => F.Eq(x => x.LostObjectId, id);


    public static FilterDefinition<Ticket> ByLocation(GeoPoint location)
        => F.Eq(x => x.Location!.Coordinates, location.Coordinates);

    public static FilterDefinition<Ticket> ByComplaintTitle(string title)
        => F.Regex(x => x.ComplaintDetails!.Title, new BsonRegularExpression(Regex.Escape(title), "i"));

    public static FilterDefinition<Ticket> ByComplaintDescription(string description)
        => F.Regex(x => x.ComplaintDetails!.Description, new BsonRegularExpression(Regex.Escape(description), "i"));

    public static FilterDefinition<Ticket> ByComplaintStatus(Complainenum status)
        => F.Eq(x => x.ComplaintDetails!.Status, status);

    public static SortDefinition<Ticket> Sort(TicketSortBy field, bool desc)
    {
        var s = Builders<Ticket>.Sort;
        return field switch
        {
            TicketSortBy.Status => desc ? s.Descending(x => x.TicketType) : s.Ascending(x => x.TicketType),
            _ => desc ? s.Descending(x => x.ReportedAt) : s.Ascending(x => x.ReportedAt),
        };
    }
}
