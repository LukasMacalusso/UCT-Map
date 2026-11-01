using Incident.Domain.Entities;
using Incident.Infrastructure.Persistence;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;
using NSubstitute;

namespace Incident.UnitTests.Infrastructure.Persistence.Repositories;

/// <summary>
/// Cubre la implementación base de repositorio contra una colección de Mongo
/// simulada, sin necesitar un servidor real.
/// </summary>
public class MongoRepositoryTests
{
    private readonly IMongoDbContext _context = Substitute.For<IMongoDbContext>();
    private readonly IMongoCollection<LostObject> _collection = Substitute.For<IMongoCollection<LostObject>>();
    private readonly MongoRepository<LostObject> _repository;

    public MongoRepositoryTests()
    {
        _context.GetCollection<LostObject>(Arg.Any<string>()).Returns(_collection);
        _repository = new MongoRepository<LostObject>(_context, "lost_objects");
    }

    private static LostObject NewLostObject(string? id = null) => new()
    {
        Id = id,
        StructureRefId = Guid.NewGuid(),
        Title = "Mochila negra",
        Description = "Dejada en la biblioteca",
        Status = Objectenum.Pending,
        ReportedAt = new DateTime(2026, 10, 14, 20, 0, 0, DateTimeKind.Utc),
        PhotoUrl = "https://campus.uct.cl/mochila.png"
    };

    private static IAsyncCursor<LostObject> CreateCursor(params LostObject[] items)
    {
        var cursor = Substitute.For<IAsyncCursor<LostObject>>();
        cursor.MoveNextAsync(Arg.Any<CancellationToken>()).Returns(true, false);
        cursor.Current.Returns(items);
        return cursor;
    }

    private void ConfigureFind(params LostObject[] items)
    {
        var cursor = CreateCursor(items);
        _collection.FindAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<FindOptions<LostObject, LostObject>>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(cursor));
    }

    [Fact]
    public void Constructor_UsaElNombreDeColeccionIndicado()
    {
        _context.Received(1).GetCollection<LostObject>("lost_objects");
    }

    [Theory]
    [InlineData("no-es-un-objectid")]
    [InlineData("")]
    public async Task GetByIdAsync_ConIdInvalido_RetornaNull(string id)
    {
        var result = await _repository.GetByIdAsync(id);

        Assert.Null(result);
    }

    [Fact]
    public async Task GetByIdAsync_ConIdValido_DevuelveElDocumento()
    {
        var entity = NewLostObject(ObjectId.GenerateNewId().ToString());
        ConfigureFind(entity);

        var result = await _repository.GetByIdAsync(entity.Id!);

        Assert.Same(entity, result);
    }

    [Fact]
    public async Task GetAllAsync_DevuelveTodosLosDocumentos()
    {
        var first = NewLostObject(ObjectId.GenerateNewId().ToString());
        var second = NewLostObject(ObjectId.GenerateNewId().ToString());
        ConfigureFind(first, second);

        var result = await _repository.GetAllAsync();

        Assert.Equal(new[] { first, second }, result);
    }

    [Fact]
    public async Task CreateAsync_InsertaElDocumento()
    {
        var entity = NewLostObject();

        await _repository.CreateAsync(entity);

        await _collection.Received(1).InsertOneAsync(
            entity,
            Arg.Any<InsertOneOptions>(),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task UpdateAsync_ReemplazaElDocumento()
    {
        var entity = NewLostObject(ObjectId.GenerateNewId().ToString());
        _collection.ReplaceOneAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<LostObject>(),
                Arg.Any<ReplaceOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ReplaceOneResult>(
                new ReplaceOneResult.Acknowledged(1, 1, null)));

        await _repository.UpdateAsync(entity.Id!, entity);

        await _collection.Received(1).ReplaceOneAsync(
            Arg.Any<FilterDefinition<LostObject>>(),
            entity,
            Arg.Any<ReplaceOptions>(),
            Arg.Any<CancellationToken>());
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(0, false)]
    public async Task DeleteAsync_DevuelveSiSeEliminoElDocumento(long deletedCount, bool expected)
    {
        var deleteResult = Task.FromResult<DeleteResult>(new DeleteResult.Acknowledged(deletedCount));
        _collection.DeleteOneAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<DeleteOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(deleteResult);
        _collection.DeleteOneAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<CancellationToken>())
            .Returns(deleteResult);

        var result = await _repository.DeleteAsync(ObjectId.GenerateNewId().ToString());

        Assert.Equal(expected, result);
    }
}
