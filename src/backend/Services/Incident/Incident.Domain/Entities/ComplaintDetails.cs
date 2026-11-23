using MongoDB.Bson.Serialization.Attributes;
using MongoDB.Bson;

namespace Incident.Domain.Entities;

public class ComplaintDetails
{
    public required string Title { get; set; }

    public required string Description { get; set; }

    public required Complainenum Status { get; set; }
}
