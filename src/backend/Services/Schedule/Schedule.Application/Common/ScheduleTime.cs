using System;

namespace Schedule.Application.Common;

// Meeting dates are stored as UTC instants in a "timestamp without time zone" column.
// Values sent with "Z" or an offset are converted to that same UTC form, so every query uses one convention.
public static class ScheduleTime
{
    public static DateTime ToUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Local => DateTime.SpecifyKind(value.ToUniversalTime(), DateTimeKind.Unspecified),
        DateTimeKind.Utc => DateTime.SpecifyKind(value, DateTimeKind.Unspecified),
        _ => value
    };
}
