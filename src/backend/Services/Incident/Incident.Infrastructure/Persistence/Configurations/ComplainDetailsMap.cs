using MongoDB.Bson;
using Incident.Domain.Entities;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
namespace Incident.Infrastructure.Persistence.Configurations;

public class ComplainDetailsMap : BsonClassMap<ComplaintDetails>
{
    public ComplainDetailsMap()
    {
        AutoMap();
        MapMember(x => x.Title)
                    .SetElementName("title");

        MapMember(x => x.Description)
                    .SetElementName("description");

        MapMember(x => x.Status)
                    .SetElementName("status")
                    .SetSerializer(new EnumSerializer<Complainenum>(BsonType.String));
    }

}
