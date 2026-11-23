using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using Incident.Domain.Entities;
using MongoDB.Bson.Serialization.IdGenerators;
namespace Incident.Infrastructure.Persistence.Configurations;

public class LostObjectMap : BsonClassMap<LostObject>
{
    public LostObjectMap()
    {
        AutoMap();
        MapIdMember(x => x.Id)
                    .SetSerializer(
                        new StringSerializer(BsonType.ObjectId)
                    )
                    .SetIdGenerator(StringObjectIdGenerator.Instance);

        MapMember(x => x.StructureRefId)
                    .SetElementName("structure_id")
                    .SetSerializer(
                        new GuidSerializer(BsonType.String)
                    );
        MapMember(x => x.UserRefId)
                    .SetElementName("user_id")
                    .SetSerializer(
                        new GuidSerializer(BsonType.String)
                    );

        MapMember(x => x.Title)
                    .SetElementName("title");

        MapMember(x => x.Description)
                    .SetElementName("description");

        MapMember(x => x.Status)
                    .SetElementName("status")
                    .SetSerializer(
                        new EnumSerializer<Objectenum>(BsonType.String)
                    );

        MapMember(x => x.ReportedAt)
                    .SetElementName("date_lost_object");

        MapMember(x => x.PhotoUrl)
                    .SetElementName("photo_url");

    }

}
