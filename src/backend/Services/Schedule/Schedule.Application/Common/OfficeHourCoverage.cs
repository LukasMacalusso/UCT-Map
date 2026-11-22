using System;
using System.Collections.Generic;
using System.Linq;
using Schedule.Domain.Entities;

namespace Schedule.Application.Common;

// A meeting is covered when it fits entirely inside one office hour, compared in campus time.
public static class OfficeHourCoverage
{
    public static bool Covers(IEnumerable<OfficeHour> officeHours, Meeting meeting, CampusTimeZone timeZone)
    {
        var start = timeZone.ToLocal(meeting.ScheduledAt);
        var end = timeZone.ToLocal(meeting.EndsAt);
        if (end.Date != start.Date) return false;

        return officeHours.Any(o => o.Contains(start.DayOfWeek, TimeOnly.FromDateTime(start), TimeOnly.FromDateTime(end)));
    }
}
