using System;

namespace Schedule.Application.Common;

// Office hours are wall-clock times on campus, while meeting dates are UTC instants.
// This converts between both so they can be compared.
public sealed class CampusTimeZone(TimeZoneInfo zone)
{
    public const string DefaultId = "America/Santiago";

    public static CampusTimeZone FromId(string? id) =>
        new(TimeZoneInfo.FindSystemTimeZoneById(string.IsNullOrWhiteSpace(id) ? DefaultId : id));

    public DateTime ToLocal(DateTime utc) => DateTime.SpecifyKind(
        TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utc, DateTimeKind.Utc), zone), DateTimeKind.Unspecified);

    public DateTime ToUtc(DateTime local)
    {
        var wallClock = DateTime.SpecifyKind(local, DateTimeKind.Unspecified);
        // A time skipped by a daylight saving change does not exist; use the first valid one after it.
        if (zone.IsInvalidTime(wallClock)) wallClock = wallClock.AddHours(1);
        return DateTime.SpecifyKind(TimeZoneInfo.ConvertTimeToUtc(wallClock, zone), DateTimeKind.Unspecified);
    }
}
