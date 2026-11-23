using System;
using System.Threading;
using System.Threading.Tasks;

namespace Schedule.Domain.Interfaces;

public interface IUnitOfWork
{
    Task<T> ExecuteInTransactionAsync<T>(
        Func<Task<T>> operation,
        CancellationToken cancellationToken = default);
}
