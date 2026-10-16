using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Incident.Domain.Entities;

public class LostObject
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; init; }

    [BsonElement("structure_id")]
    [BsonRepresentation(BsonType.String)]
    public required Guid StructureRefId { get; init; }

    [BsonElement("title")]
    public required string Title { get; init; }

    [BsonElement("description")]
    public required string Description { get; init; }

    [BsonElement("status")]
    [BsonRepresentation(BsonType.String)]
    public required Objectenum Status { get; set; }

    [BsonElement("date_lost_object")]
    [BsonRepresentation(BsonType.DateTime)]
    public required DateTime ReportedAt { get; init; }

    [BsonElement("photo_url")]
    public string? PhotoUrl { get; init; }
}
