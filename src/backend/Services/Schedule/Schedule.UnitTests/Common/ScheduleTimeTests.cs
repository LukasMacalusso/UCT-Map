using Schedule.Application.Common;

namespace Schedule.UnitTests.Common;

public class ScheduleTimeTests
{
    private static readonly DateTime TenAm = new(2026, 11, 17, 10, 0, 0);

    [Fact]
    public void ToUtc_WhenValueHasNoTimeZone_KeepsIt()
    {
        var result = ScheduleTime.ToUtc(TenAm);

        Assert.Equal(TenAm, result);
        Assert.Equal(DateTimeKind.Unspecified, result.Kind);
    }

    [Fact]
    public void ToUtc_WhenValueIsUtc_KeepsTheTimeWithoutKind()
    {
        var result = ScheduleTime.ToUtc(DateTime.SpecifyKind(TenAm, DateTimeKind.Utc));

        Assert.Equal(TenAm, result);
        Assert.Equal(DateTimeKind.Unspecified, result.Kind);
    }

    [Fact]
    public void ToUtc_WhenValueIsLocal_ConvertsItToUtc()
    {
        var local = DateTime.SpecifyKind(TenAm, DateTimeKind.Local);

        var result = ScheduleTime.ToUtc(local);

        Assert.Equal(local.ToUniversalTime(), DateTime.SpecifyKind(result, DateTimeKind.Utc));
        Assert.Equal(DateTimeKind.Unspecified, result.Kind);
    }
}
