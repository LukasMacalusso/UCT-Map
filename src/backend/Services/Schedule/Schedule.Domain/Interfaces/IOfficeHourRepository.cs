using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Schedule.Domain.Entities;

namespace Schedule.Domain.Interfaces;

public interface IOfficeHourRepository
{
    Task<OfficeHour?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<OfficeHour>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<IReadOnlyList<OfficeHour>> GetByTeacherAsync(
        Guid teacherRefId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<OfficeHour>> GetInRoomsAsync(
        IReadOnlyCollection<Guid> structureRefIds,
        DayOfWeek dayOfWeek,
        TimeOnly start,
        TimeOnly end,
        CancellationToken cancellationToken = default);

    // Blocks on that weekday that overlap the range and belong to the same teacher or room.
    Task<IReadOnlyList<OfficeHour>> GetOverlappingAsync(
        Guid teacherRefId,
        Guid? structureRefId,
        DayOfWeek dayOfWeek,
        TimeOnly start,
        TimeOnly end,
        CancellationToken cancellationToken = default);

    Task AddAsync(OfficeHour officeHour, CancellationToken cancellationToken = default);

    Task UpdateAsync(OfficeHour officeHour, CancellationToken cancellationToken = default);

    Task RemoveAsync(OfficeHour officeHour, CancellationToken cancellationToken = default);
}
