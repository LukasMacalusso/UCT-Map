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
        var officeHours = await dbContext.OfficeHours
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return officeHours
            .OrderBy(o => o.TeacherRefId)
            .ThenBy(o => WeekdayOrder(o.DayOfWeek))
            .ThenBy(o => o.StartTime)
            .ToList();
    }

    public async Task<IReadOnlyList<OfficeHour>> GetByTeacherAsync(
        Guid teacherRefId,
        CancellationToken cancellationToken = default)
    {
        var officeHours = await dbContext.OfficeHours
            .AsNoTracking()
            .Where(o => o.TeacherRefId == teacherRefId)
            .ToListAsync(cancellationToken);

        return officeHours
            .OrderBy(o => WeekdayOrder(o.DayOfWeek))
            .ThenBy(o => o.StartTime)
            .ToList();
    }

    public async Task AddAsync(OfficeHour officeHour, CancellationToken cancellationToken = default)
    {
        await dbContext.OfficeHours.AddAsync(officeHour, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    // DayOfWeek is stored as text, so ordering in SQL would be alphabetical.
    // Sorting in memory by weekday, Monday first.
    private static int WeekdayOrder(DayOfWeek day) => ((int)day + 6) % 7;
}
