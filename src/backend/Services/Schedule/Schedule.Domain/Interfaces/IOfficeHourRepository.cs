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

    Task AddAsync(OfficeHour officeHour, CancellationToken cancellationToken = default);
}
