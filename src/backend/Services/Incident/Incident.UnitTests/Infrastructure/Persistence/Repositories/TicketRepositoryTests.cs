using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.Infrastructure.Persistence;
using Incident.Infrastructure.Persistence.Repositories;
using MongoDB.Bson;
using MongoDB.Driver;
using NSubstitute;

namespace Incident.UnitTests.Infrastructure.Persistence.Repositories;

/// <summary>
/// Cubre el repositorio de tickets contra una colección simulada.
/// </summary>
public class TicketRepositoryTests
{
    private readonly IMongoDbContext _context = Substitute.For<IMongoDbContext>();
    private readonly IMongoCollection<Ticket> _collection = Substitute.For<IMongoCollection<Ticket>>();
    private readonly TicketRepository _repository;

    public TicketRepositoryTests()
    {
        _context.GetCollection<Ticket>(Arg.Any<string>()).Returns(_collection);
        _repository = new TicketRepository(_context);
    }

    private static Ticket NewTicket(string? id = null) => new()
    {
        Id = id,
        UserRefId = Guid.NewGuid(),
        StructureRefId = Guid.NewGuid(),
        TicketType = Tickets.Pending,
        IsActive = true,
        ReportedAt = new DateTime(2026, 10, 14, 20, 0, 0, DateTimeKind.Utc),
        Location = new GeoPoint(-71.2345, -33.0456),
        ComplaintDetails = new ComplaintDetails
        {
            Title = "Fuga de agua",
            Description = "Baño del segundo piso",
            Status = Complainenum.Claim
        }
    };

    private static IAsyncCursor<Ticket> CreateCursor(params Ticket[] items)
    {
        var cursor = Substitute.For<IAsyncCursor<Ticket>>();
        cursor.MoveNextAsync(Arg.Any<CancellationToken>()).Returns(true, false);
        cursor.Current.Returns(items);
        return cursor;
    }

    private void ConfigureUpdate(long modifiedCount) =>
        _collection.UpdateOneAsync(
                Arg.Any<FilterDefinition<Ticket>>(),
                Arg.Any<UpdateDefinition<Ticket>>(),
                Arg.Any<UpdateOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult<UpdateResult>(
                new UpdateResult.Acknowledged(1, modifiedCount, null)));

    [Theory]
    [InlineData(1, true)]
    [InlineData(0, false)]
    public async Task UpdateStatusAsync_DevuelveSiSeModifico(long modifiedCount, bool expected)
    {
        ConfigureUpdate(modifiedCount);
        var entity = NewTicket(ObjectId.GenerateNewId().ToString());

        var result = await _repository.UpdateStatusAsync(entity, (int)Tickets.Resolved);

        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(0, false)]
    public async Task UpdateStatusComplainAsync_DevuelveSiSeModifico(long modifiedCount, bool expected)
    {
        ConfigureUpdate(modifiedCount);
        var entity = NewTicket(ObjectId.GenerateNewId().ToString());

        var result = await _repository.UpdateStatusComplainAsync(entity, (int)Complainenum.Match);

        Assert.Equal(expected, result);
    }

    [Fact]
    public async Task SearchAsync_DevuelveLaPaginaConElTotal()
    {
        var first = NewTicket(ObjectId.GenerateNewId().ToString());
        var second = NewTicket(ObjectId.GenerateNewId().ToString());

        _collection.CountDocumentsAsync(
                Arg.Any<FilterDefinition<Ticket>>(),
                Arg.Any<CountOptions>(),
                Arg.Any<CancellationToken>())
            .Returns(2L);

        var cursor = CreateCursor(first, second);
        _collection.FindAsync(
                Arg.Any<FilterDefinition<Ticket>>(),
                Arg.Any<FindOptions<Ticket, Ticket>>(),
                Arg.Any<CancellationToken>())
            .Returns(Task.FromResult(cursor));

        var criteria = new TicketSearchCriteria(
            UserRefId: Guid.NewGuid(),
            StructureRefId: Guid.NewGuid(),
            Type: Tickets.Pending,
            IsActive: true,
            SortBy: TicketSortBy.Status,
            Location: new GeoPoint(-71.2345, -33.0456),
            LostObjectId: ObjectId.GenerateNewId().ToString(),
            ComplaintDetails: new ComplaintSearchCriteria("Fuga", "Baño", Complainenum.Claim),
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
