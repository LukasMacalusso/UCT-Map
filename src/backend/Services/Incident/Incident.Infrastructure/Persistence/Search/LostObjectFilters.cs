using System.Text.RegularExpressions;
using Incident.Domain.Entities;
using Incident.Domain.Queries;
using MongoDB.Bson;
using MongoDB.Driver;

namespace Incident.Infrastructure.Persistence.Search;

internal static class LostObjectFilters
{
    private static readonly FilterDefinitionBuilder<LostObject> F = Builders<LostObject>.Filter;

    public static FilterDefinition<LostObject> Build(LostObjectSearchCriteria c)
    {
        var parts = new List<FilterDefinition<LostObject>>();

        if (c.Title is not null) parts.Add(ByTitle(c.Title));
        if (c.StructureId is { } s) parts.Add(ByStructure(s));
        if (c.Status is { } st) parts.Add(ByStatus(st));

        return parts.Count == 0 ? F.Empty : F.And(parts);
    }

    public static FilterDefinition<LostObject> ByTitle(string title)
        => F.Regex(x => x.Title, new BsonRegularExpression(Regex.Escape(title), "i"));

    public static FilterDefinition<LostObject> ByStructure(Guid id)
        => F.Eq(x => x.StructureRefId, id);

    public static FilterDefinition<LostObject> ByStatus(Objectenum status)
        => F.Eq(x => x.Status, status);

    public static SortDefinition<LostObject> Sort(LostObjectSortField field, bool desc)
    {
        var s = Builders<LostObject>.Sort;
        return field switch
        {
            LostObjectSortField.Title => desc ? s.Descending(x => x.Title) : s.Ascending(x => x.Title),
            LostObjectSortField.Status => desc ? s.Descending(x => x.Status) : s.Ascending(x => x.Status),
            _ => desc ? s.Descending(x => x.ReportedAt) : s.Ascending(x => x.ReportedAt),
        };
    }
}
