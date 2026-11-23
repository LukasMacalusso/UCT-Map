using Schedule.Domain.Entities;
using Schedule.Domain.Interfaces;

namespace Schedule.UnitTests.Fakes;

public class FakeOfficeHourRepository : IOfficeHourRepository
{
    public List<OfficeHour> Items { get; } = [];

    public Task<OfficeHour?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(Items.FirstOrDefault(o => o.Id == id));
    }

    public Task<IReadOnlyList<OfficeHour>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        IReadOnlyList<OfficeHour> result = Items
            .OrderBy(o => o.TeacherRefId)
            .ThenBy(o => o.DayOfWeek)
            .ThenBy(o => o.StartTime)
            .ToList();

        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<OfficeHour>> GetByTeacherAsync(
        Guid teacherRefId,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<OfficeHour> result = Items
            .Where(o => o.TeacherRefId == teacherRefId)
            .OrderBy(o => o.DayOfWeek)
            .ThenBy(o => o.StartTime)
            .ToList();

        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<OfficeHour>> GetInRoomsAsync(
        IReadOnlyCollection<Guid> structureRefIds,
        DayOfWeek dayOfWeek,
        TimeOnly start,
        TimeOnly end,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<OfficeHour> result = Items
            .Where(o => o.StructureRefId != null && structureRefIds.Contains(o.StructureRefId.Value))
            .Where(o => o.DayOfWeek == dayOfWeek && o.StartTime < end && o.EndTime > start)
            .OrderBy(o => o.StartTime)
            .ToList();

        return Task.FromResult(result);
    }

    public Task<IReadOnlyList<OfficeHour>> GetOverlappingAsync(
        Guid teacherRefId,
        Guid? structureRefId,
        DayOfWeek dayOfWeek,
        TimeOnly start,
        TimeOnly end,
        CancellationToken cancellationToken = default)
    {
        IReadOnlyList<OfficeHour> result = Items
            .Where(o => o.TeacherRefId == teacherRefId || (structureRefId != null && o.StructureRefId == structureRefId))
            .Where(o => o.Overlaps(dayOfWeek, start, end))
            .ToList();

        return Task.FromResult(result);
    }

    public Task AddAsync(OfficeHour officeHour, CancellationToken cancellationToken = default)
    {
        Items.Add(officeHour);
        return Task.CompletedTask;
    }

    // Items holds the same instance the handler edits, so there is nothing else to save.
    public Task UpdateAsync(OfficeHour officeHour, CancellationToken cancellationToken = default)
    {
        return Task.CompletedTask;
    }

    public Task RemoveAsync(OfficeHour officeHour, CancellationToken cancellationToken = default)
    {
        Items.Remove(officeHour);
        return Task.CompletedTask;
    }
}
