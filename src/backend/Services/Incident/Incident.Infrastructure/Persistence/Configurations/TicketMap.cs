
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using Incident.Domain.Entities;
using MongoDB.Bson.Serialization.IdGenerators;
namespace Incident.Infrastructure.Persistence.Configurations;

public class TicketMap : BsonClassMap<Ticket>
{
    public TicketMap()
    {
        AutoMap();

        MapIdMember(x => x.Id)
            .SetSerializer(
                new StringSerializer(BsonType.ObjectId)
            )
            .SetIdGenerator(StringObjectIdGenerator.Instance);

        MapMember(x => x.UserRefId)
            .SetElementName("user_id")
            .SetSerializer(new GuidSerializer(BsonType.String));

        MapMember(x => x.StructureRefId)
            .SetElementName("structure_id")
            .SetSerializer(new GuidSerializer(BsonType.String));

        MapMember(x => x.TicketType)
            .SetElementName("ticket_type")
            .SetSerializer(new EnumSerializer<Tickets>(BsonType.String));

        MapMember(x => x.IsActive)
            .SetElementName("is_active");

        MapMember(x => x.ReportedAt)
            .SetElementName("date_ticket");

        MapMember(x => x.Location)
            .SetElementName("location");

        MapMember(x => x.LostObjectId)
            .SetElementName("object_id")
            .SetSerializer(new StringSerializer(BsonType.ObjectId));

        MapMember(x => x.ComplaintDetails)
            .SetElementName("complaint_details");
    }
}
