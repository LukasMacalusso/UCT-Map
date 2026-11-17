using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class RoomHandler
{
    public const string MeetingReason = "Meeting";
    public const string OfficeHourReason = "OfficeHour";

    private readonly IMeetingRepository _meetingRepository;
    private readonly IOfficeHourRepository _officeHourRepository;
    private readonly CampusTimeZone _timeZone;

    public RoomHandler(IMeetingRepository meetingRepository, IOfficeHourRepository officeHourRepository, CampusTimeZone timeZone)
    {
        _meetingRepository = meetingRepository;
        _officeHourRepository = officeHourRepository;
        _timeZone = timeZone;
    }

    public async Task<ErrorOr<RoomAvailabilityDto>> GetAvailabilityAsync(
        IReadOnlyCollection<Guid> roomIds,
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken)
    {
        if (roomIds.Count == 0) return Error.Validation(description: "At least one 'roomIds' value is required.");
        if (roomIds.Contains(Guid.Empty)) return Error.Validation(description: "The 'roomIds' values cannot be empty.");
        (from, to) = (ScheduleTime.ToUtc(from), ScheduleTime.ToUtc(to));
        if (to <= from) return Error.Validation(description: "The 'to' parameter must be later than 'from'.");

        // Meetings are compared in UTC; office hours in campus time, which also decides the day.
        var localFrom = _timeZone.ToLocal(from);
        var localTo = _timeZone.ToLocal(to);
        if (localTo.Date != localFrom.Date) return Error.Validation(description: "The 'from' and 'to' parameters must be on the same day.");

        var candidates = roomIds.Distinct().ToList();

        var meetings = await _meetingRepository.GetActiveInRoomsAsync(candidates, from, to, cancellationToken);
        var officeHours = await _officeHourRepository.GetInRoomsAsync(
            candidates, localFrom.DayOfWeek, TimeOnly.FromDateTime(localFrom), TimeOnly.FromDateTime(localTo), cancellationToken);

        var occupancies = meetings
            .Select(m => new RoomOccupancyDto(m.StructureRefId!.Value, MeetingReason, m.ScheduledAt, m.EndsAt))
            .Concat(officeHours.Select(o => new RoomOccupancyDto(
                o.StructureRefId!.Value,
                OfficeHourReason,
                _timeZone.ToUtc(localFrom.Date.Add(o.StartTime.ToTimeSpan())),
                _timeZone.ToUtc(localFrom.Date.Add(o.EndTime.ToTimeSpan())))))
            .OrderBy(o => o.OccupiedFrom)
            .ToList();

        var occupiedRooms = occupancies.Select(o => o.StructureRefId).ToHashSet();
        var freeRooms = candidates.Where(id => !occupiedRooms.Contains(id)).ToList();

        return new RoomAvailabilityDto(from, to, freeRooms, occupancies);
    }
}
