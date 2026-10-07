using System.Data;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.Infrastructure.Persistence;

public class UnitOfWork(ScheduleDbContext dbContext) : IUnitOfWork
{
    public async Task<T> ExecuteInTransactionAsync<T>(
        Func<Task<T>> operation,
        CancellationToken cancellationToken = default)
    {
        if (!dbContext.Database.IsRelational())
        {
            return await operation();
        }

        try
        {
            await using var transaction = await dbContext.Database
                .BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

            var result = await operation();
            await transaction.CommitAsync(cancellationToken);
            return result;
        }
        catch (Exception exception) when (IsSerializationFailure(exception))
        {
            throw new ConcurrencyConflictException();
        }
    }

    private static bool IsSerializationFailure(Exception exception)
    {
        return exception is PostgresException { SqlState: PostgresErrorCodes.SerializationFailure }
            || exception.InnerException is PostgresException { SqlState: PostgresErrorCodes.SerializationFailure };
    }
}
