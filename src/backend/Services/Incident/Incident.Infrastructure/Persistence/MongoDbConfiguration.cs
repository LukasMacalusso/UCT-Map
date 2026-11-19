using Incident.Domain.Entities;
using MongoDB.Bson.Serialization;
using Incident.Infrastructure.Persistence.Configurations;
namespace Incident.Infrastructure.Persistence;

public static class MongoDbConfiguration
{
    private static readonly object Gate = new();
    private static bool _registered;

    public static void RegisterClassMaps()
    {
        if (_registered) return;

        lock (Gate)
        {
            if (_registered) return;

            if (!BsonClassMap.IsClassMapRegistered(typeof(Ticket)))
                BsonClassMap.RegisterClassMap(new TicketMap());

            if (!BsonClassMap.IsClassMapRegistered(typeof(LostObject)))
                BsonClassMap.RegisterClassMap(new LostObjectMap());

            if (!BsonClassMap.IsClassMapRegistered(typeof(ComplaintDetails)))
                BsonClassMap.RegisterClassMap(new ComplainDetailsMap());

            if (!BsonClassMap.IsClassMapRegistered(typeof(GeoPoint)))
                BsonClassMap.RegisterClassMap(new GeoPointMap());

            _registered = true;
        }
    }
}
