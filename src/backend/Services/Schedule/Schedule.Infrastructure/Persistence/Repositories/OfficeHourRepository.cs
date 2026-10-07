using Microsoft.EntityFrameworkCore;
using Schedule.Domain.Entities;
using Schedule.Domain.Interfaces;

namespace Schedule.Infrastructure.Persistence.Repositories;

public class OfficeHourRepository(ScheduleDbContext dbContext) : IOfficeHourRepository
{
    public async Task<OfficeHour?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await dbContext.OfficeHours
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<OfficeHour>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await dbContext.OfficeHours
            .AsNoTracking()
            .OrderBy(o => o.TeacherRefId)
            .ThenBy(o => o.DayOfWeek)
            .ThenBy(o => o.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<OfficeHour>> GetByTeacherAsync(
        Guid teacherRefId,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.OfficeHours
            .AsNoTracking()
            .Where(o => o.TeacherRefId == teacherRefId)
            .OrderBy(o => o.DayOfWeek)
            .ThenBy(o => o.StartTime)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(OfficeHour officeHour, CancellationToken cancellationToken = default)
    {
        await dbContext.OfficeHours.AddAsync(officeHour, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
