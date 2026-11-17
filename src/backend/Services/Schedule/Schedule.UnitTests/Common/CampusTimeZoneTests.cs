using Schedule.Application.Common;

namespace Schedule.UnitTests.Common;

public class CampusTimeZoneTests
{
    private readonly CampusTimeZone _santiago = CampusTimeZone.FromId("America/Santiago");

    [Theory]
    [InlineData(11, 13, 10)]
    [InlineData(7, 14, 10)]
    public void ToLocal_AppliesSummerAndWinterOffsets(int month, int utcHour, int expectedLocalHour)
    {
        var local = _santiago.ToLocal(new DateTime(2026, month, 17, utcHour, 0, 0));

        Assert.Equal(expectedLocalHour, local.Hour);
        Assert.Equal(DateTimeKind.Unspecified, local.Kind);
    }

    [Fact]
    public void ToUtc_IsTheInverseOfToLocal()
    {
        var utc = new DateTime(2026, 11, 17, 13, 0, 0);

        Assert.Equal(utc, _santiago.ToUtc(_santiago.ToLocal(utc)));
    }

    [Fact]
    public void ToUtc_WhenTimeIsSkippedByDaylightSaving_UsesTheNextValidHour()
    {
        // Clocks jump from 00:00 to 01:00 on 2026-09-06, so 00:30 does not exist and becomes 01:30 (UTC-3).
        var utc = _santiago.ToUtc(new DateTime(2026, 9, 6, 0, 30, 0));

        Assert.Equal(new DateTime(2026, 9, 6, 4, 30, 0), utc);
    }

    [Fact]
    public void FromId_WithoutId_UsesSantiago()
    {
        var local = CampusTimeZone.FromId(null).ToLocal(new DateTime(2026, 11, 17, 13, 0, 0));

        Assert.Equal(10, local.Hour);
    }
}
