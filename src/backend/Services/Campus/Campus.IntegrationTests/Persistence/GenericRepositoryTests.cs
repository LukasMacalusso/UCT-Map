using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Campus.Domain.Entities;
using Campus.Domain.ValueObjects;
using Campus.Infrastructure.Persistence;
using Campus.IntegrationTests.Fixtures;
using Microsoft.EntityFrameworkCore;
using Xunit;
using CampusEntity = Campus.Domain.Entities.Campus;

namespace Campus.IntegrationTests.Persistence;

[Collection(PostgreSqlCollection.Name)]
public class GenericRepositoryTests : IAsyncLifetime
{
    private readonly PostgreSqlFixture _fixture;
    private CampusDbContext _dbContext = null!;
    private GenericRepository<CampusEntity> _repository = null!;

    public GenericRepositoryTests(PostgreSqlFixture fixture) => _fixture = fixture;

    public async Task InitializeAsync()
    {
        if (_fixture.IsAvailable)
        {
            var options = new DbContextOptionsBuilder<CampusDbContext>()
                .UseNpgsql(_fixture.ConnectionString)
                .Options;

            _dbContext = new CampusDbContext(options);
            await _dbContext.Database.MigrateAsync();
            _repository = new GenericRepository<CampusEntity>(_dbContext);
        }
    }

    public async Task DisposeAsync()
    {
        if (_dbContext is not null)
        {
            await _dbContext.DisposeAsync();
        }
    }

    [DockerFact]
    public async Task AddAndGetByIdAsync_PersistsAndRetrievesEntity()
    {
        var campus = new CampusEntity("Repo Test Campus", "Dirección Repo", new Coordinate(-38.7, -72.5));

        await _repository.AddAsync(campus, CancellationToken.None);
        await _repository.SaveChangesAsync(CancellationToken.None);

        var retrieved = await _repository.GetByIdAsync(campus.Id, CancellationToken.None);

        Assert.NotNull(retrieved);
        Assert.Equal("Repo Test Campus", retrieved.Name);
    }

    [DockerFact]
    public async Task GetAllAsync_WithPredicate_FiltersCorrectly()
    {
        var campus1 = new CampusEntity("Filtro Alpha", "Dir", new Coordinate(0, 0));
        var campus2 = new CampusEntity("Filtro Beta", "Dir", new Coordinate(0, 0));

        await _repository.AddAsync(campus1, CancellationToken.None);
        await _repository.AddAsync(campus2, CancellationToken.None);
        await _repository.SaveChangesAsync(CancellationToken.None);

        var filtered = await _repository.GetAllAsync(c => c.Name.Contains("Alpha"), CancellationToken.None);

        var list = filtered.ToList();
        Assert.Contains(list, c => c.Id == campus1.Id);
        Assert.DoesNotContain(list, c => c.Id == campus2.Id);
    }

    [DockerFact]
    public async Task ExistsAsync_ReturnsTrueWhenEntityExists()
    {
        var campus = new CampusEntity("Campus Existe", "Dir", new Coordinate(0, 0));
        await _repository.AddAsync(campus, CancellationToken.None);
        await _repository.SaveChangesAsync(CancellationToken.None);

        var exists = await _repository.ExistsAsync(c => c.Id == campus.Id, CancellationToken.None);
        var notExists = await _repository.ExistsAsync(c => c.Id == Guid.NewGuid(), CancellationToken.None);

        Assert.True(exists);
        Assert.False(notExists);
    }

    [DockerFact]
    public async Task Update_ModifiesPersistedEntity()
    {
        var campus = new CampusEntity("Antes de Modificar", "Dir", new Coordinate(0, 0));
        await _repository.AddAsync(campus, CancellationToken.None);
        await _repository.SaveChangesAsync(CancellationToken.None);

        campus.Update("Después de Modificar", "Nueva Dir", new Coordinate(1, 1));
        _repository.Update(campus);
        await _repository.SaveChangesAsync(CancellationToken.None);

        var retrieved = await _repository.GetByIdAsync(campus.Id, CancellationToken.None);
        Assert.NotNull(retrieved);
        Assert.Equal("Después de Modificar", retrieved.Name);
    }

    [DockerFact]
    public async Task Delete_RemovesEntityFromDatabase()
    {
        var campus = new CampusEntity("Para Eliminar Repo", "Dir", new Coordinate(0, 0));
        await _repository.AddAsync(campus, CancellationToken.None);
        await _repository.SaveChangesAsync(CancellationToken.None);

        _repository.Delete(campus);
        await _repository.SaveChangesAsync(CancellationToken.None);

        var retrieved = await _repository.GetByIdAsync(campus.Id, CancellationToken.None);
        Assert.Null(retrieved);
    }
}
