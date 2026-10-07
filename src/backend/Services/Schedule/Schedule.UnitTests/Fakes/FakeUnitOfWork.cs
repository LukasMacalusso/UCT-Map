using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.UnitTests.Fakes;

public class FakeUnitOfWork : IUnitOfWork
{
    public bool SimulateConcurrencyConflict { get; set; }

    public async Task<T> ExecuteInTransactionAsync<T>(
        Func<Task<T>> operation,
        CancellationToken cancellationToken = default)
    {
        if (SimulateConcurrencyConflict)
        {
            throw new ConcurrencyConflictException();
        }

        return await operation();
    }
}
