using Schedule.Domain.Entities;
using Schedule.Domain.Enums;
using Schedule.Domain.Interfaces;

namespace Schedule.UnitTests.Fakes;

public class FakeMeetingRepository : IMeetingRepository
{
    public List<Meeting> Items { get; } = [];

    public List<Guid> UpdatedIds { get; } = [];

    public Task<Meeting?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Items.FirstOrDefault(m => m.Id == id));
    }

    public Task<IReadOnlyList<Meeting>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        IReadOnlyList<Meeting> result = Items.OrderBy(m => m.ScheduledAt).ToList();
        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<Meeting>> GetByTeacherAsync(
        Guid teacherRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Filter(m => m.TeacherRefId == teacherRefId, from, to));
    }

    public Task<IReadOnlyList<Meeting>> GetByStudentAsync(
        Guid studentRefId,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Filter(m => m.StudentRefId == studentRefId, from, to));
    }

    public Task<IReadOnlyList<Meeting>> GetActiveOverlappingAsync(
        Guid teacherRefId,
        Guid studentRefId,
        Guid? structureRefId,
        DateTime start,
        DateTime end,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<Meeting> result = Items
            .Where(m => m.Status != MeetingStatus.Cancelled)
            .Where(m => m.TeacherRefId == teacherRefId
                || m.StudentRefId == studentRefId
                || (structureRefId != null && m.StructureRefId == structureRefId))
            .Where(m => m.ScheduledAt < end && m.EndsAt > start)
            .ToList();

        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<Meeting>> GetActiveInRoomsAsync(
        IReadOnlyCollection<Guid> structureRefIds,
        DateTime start,
        DateTime end,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<Meeting> result = Items
            .Where(m => m.Status != MeetingStatus.Cancelled)
            .Where(m => m.StructureRefId != null && structureRefIds.Contains(m.StructureRefId.Value))
            .Where(m => m.ScheduledAt < end && m.EndsAt > start)
            .OrderBy(m => m.ScheduledAt)
            .ToList();

        return Task.FromResult(result);
    }

    public Task AddAsync(Meeting meeting, CancellationToken cancellationToken = default)
    {
        Items.Add(meeting);
        return Task.CompletedTask;
    }

    public Task UpdateAsync(Meeting meeting, CancellationToken cancellationToken = default)
    {
        UpdatedIds.Add(meeting.Id);
        return Task.CompletedTask;
    }

    private IReadOnlyList<Meeting> Filter(Func<Meeting, bool> predicate, DateTime from, DateTime to)
    {
        return Items
            .Where(predicate)
            .Where(m => m.ScheduledAt >= from && m.ScheduledAt < to)
            .OrderBy(m => m.ScheduledAt)
            .ToList();
    }
}
