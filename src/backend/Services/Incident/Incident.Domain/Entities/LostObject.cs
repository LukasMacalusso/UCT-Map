using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Incident.Domain.Entities;



public class LostObject
{

    public string? Id { get; init; }

    public required Guid StructureRefId { get; init; }


    public required string Title { get; init; }


    public required string Description { get; init; }

    public required Objectenum Status { get; set; }

    public required DateTime ReportedAt { get; init; }

    public string? PhotoUrl { get; init; }
}
