using System;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Incident.Domain.Entities;

public class Ticket
{
    public string? Id { get; init; }

    public required Guid UserRefId { get; init; }

    public required Guid StructureRefId { get; init; }

    public required Tickets TicketType { get; set; }

    public required bool IsActive { get; set; }

    public required DateTime ReportedAt { get; init; }

    public GeoPoint? Location { get; set; }

    public string? LostObjectId { get; init; }

    public ComplaintDetails? ComplaintDetails { get; init; }
}
