using MongoDB.Driver;
namespace Incident.Infrastructure.Persistence;

public interface IMongoDbContext
{
    IMongoDatabase Database { get; }
    IMongoCollection<T> GetCollection<T>(string name);
}

public class MongoDbContext : IMongoDbContext
{
    private readonly IMongoDatabase _database;
    static MongoDbContext()
    {
        MongoDbConfiguration.RegisterClassMaps();
    }
    public MongoDbContext(IMongoClient client, string databaseName)
    {
        _database = client.GetDatabase(databaseName);
    }

    public IMongoDatabase Database => _database;

    public IMongoCollection<T> GetCollection<T>(string name)
        => _database.GetCollection<T>(name);
}
