using MongoDB.Bson.Serialization.Attributes;

namespace Incident.Domain.Entities;

public class GeoPoint
{
    [BsonElement("type")]
    public string Type { get; set; } = "Point";

    [BsonElement("coordinates")]
    public double[] Coordinates { get; set; } = new double[2];

    public GeoPoint() { }

    public GeoPoint(double longitude, double latitude)
    {
        Type = "Point";
        Coordinates = new double[] { longitude, latitude };
    }
}
