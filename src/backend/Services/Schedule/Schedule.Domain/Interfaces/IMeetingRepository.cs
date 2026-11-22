using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Schedule.Domain.Entities;

namespace Schedule.Domain.Interfaces;

public interface IMeetingRepository
{
    Task<Meeting?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetByParticipantAsync(Guid userRefId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetByTeacherAsync(
        Guid teacherRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetByStudentAsync(
        Guid studentRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetActiveOverlappingAsync(
        Guid teacherRefId,
        Guid studentRefId,
        Guid? structureRefId,
        DateTime start,
        DateTime end,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Meeting>> GetActiveInRoomsAsync(
        IReadOnlyCollection<Guid> structureRefIds,
        DateTime start,
        DateTime end,
        CancellationToken cancellationToken = default);

    // Pending or confirmed meetings of the teacher that start at or after the given moment.
    Task<IReadOnlyList<Meeting>> GetUpcomingByTeacherAsync(
        Guid teacherRefId,
        DateTime from,
        CancellationToken cancellationToken = default);

    Task AddAsync(Meeting meeting, CancellationToken cancellationToken = default);

    Task UpdateAsync(Meeting meeting, CancellationToken cancellationToken = default);
}
