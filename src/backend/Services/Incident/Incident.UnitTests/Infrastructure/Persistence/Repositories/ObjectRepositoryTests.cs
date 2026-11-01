using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.Infrastructure.Persistence;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;
using NSubstitute;

namespace Incident.UnitTests.Infrastructure.Persistence.Repositories;

/// <summary>
/// Cubre el repositorio de objetos perdidos contra una colección simulada.
/// </summary>
public class ObjectRepositoryTests
{
    private readonly IMongoDbContext _context = Substitute.For<IMongoDbContext>();
    private readonly IMongoCollection<LostObject> _collection = Substitute.For<IMongoCollection<LostObject>>();
    private readonly ObjectRepository _repository;

    public ObjectRepositoryTests()
    {
        _context.GetCollection<LostObject>(Arg.Any<string>()).Returns(_collection);
        _repository = new ObjectRepository(_context);
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

    [Fact]
    public async Task CreateAsync_InsertaEnLaColeccionDeObjetos()
    {
        var entity = NewLostObject();

        await _repository.CreateAsync(entity);

        await _collection.Received(1).InsertOneAsync(
            entity,
            Arg.Any<InsertOneOptions>(),
            Arg.Any<CancellationToken>());
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(0, false)]
    public async Task UpdateStatusAsync_DevuelveSiSeModificoYActualizaLaEntidad(long modifiedCount, bool expected)
    {
        var entity = NewLostObject(ObjectId.GenerateNewId().ToString());
        _collection.ReplaceOneAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<LostObject>(),
                Arg.Any<ReplaceOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<ReplaceOneResult>(
                new ReplaceOneResult.Acknowledged(1, modifiedCount, null)));

        var result = await _repository.UpdateStatusAsync(entity, (int)Objectenum.Resolved);

        Assert.Equal(expected, result);
        Assert.Equal(Objectenum.Resolved, entity.Status);
    }

    [Fact]
    public async Task SearchAsync_DevuelveLaPaginaConElTotal()
    {
        var first = NewLostObject(ObjectId.GenerateNewId().ToString());
        var second = NewLostObject(ObjectId.GenerateNewId().ToString());

        _collection.CountDocumentsAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<CountOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(2L);

        var cursor = CreateCursor(first, second);
        _collection.FindAsync(
                Arg.Any<FilterDefinition<LostObject>>(),
                Arg.Any<FindOptions<LostObject, LostObject>>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(cursor));

        var criteria = new LostObjectSearchCriteria(
            Title: "Mochila",
            StructureId: Guid.NewGuid(),
            Status: Objectenum.Pending,
            SortBy: LostObjectSortField.Title,
            Descending: true,
            Page: 2,
            PageSize: 5);

        var result = await _repository.SearchAsync(criteria, CancellationToken.None);

        Assert.Equal(2, result.TotalCount);
        Assert.Equal(new[] { first, second }, result.Items);
        Assert.Equal(2, result.Page);
        Assert.Equal(5, result.PageSize);
    }
}
