using MongoDB.Bson;
using Incident.Domain.Entities;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
namespace Incident.Infrastructure.Persistence.Configurations;

public class GeoPointMap : BsonClassMap<GeoPoint>
{
    public GeoPointMap()
    {
        AutoMap();
        MapMember(x => x.Type)
                    .SetElementName("type");

        MapMember(x => x.Coordinates)
                    .SetElementName("coordinates");
    }
}
