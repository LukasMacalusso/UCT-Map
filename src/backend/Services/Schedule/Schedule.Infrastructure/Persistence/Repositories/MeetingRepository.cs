using Microsoft.EntityFrameworkCore;
using Schedule.Domain.Entities;
using Schedule.Domain.Interfaces;

namespace Schedule.Infrastructure.Persistence.Repositories;

public class MeetingRepository(ScheduleDbContext dbContext) : IMeetingRepository
{
    public async Task<Meeting?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await dbContext.Meetings
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<Meeting>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await dbContext.Meetings
            .AsNoTracking()
            .OrderBy(m => m.ScheduledAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Meeting>> GetByTeacherAsync(
        Guid teacherRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Meetings
            .AsNoTracking()
            .Where(m => m.TeacherRefId == teacherRefId && m.ScheduledAt >= from && m.ScheduledAt < to)
            .OrderBy(m => m.ScheduledAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Meeting>> GetByStudentAsync(
        Guid studentRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default)
    {
        return await dbContext.Meetings
            .AsNoTracking()
            .Where(m => m.StudentRefId == studentRefId && m.ScheduledAt >= from && m.ScheduledAt < to)
            .OrderBy(m => m.ScheduledAt)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(Meeting meeting, CancellationToken cancellationToken = default)
    {
        await dbContext.Meetings.AddAsync(meeting, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
