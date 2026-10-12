using System.Net;
using System.Net.Http.Json;
using Schedule.Application.DTOs;
using Schedule.IntegrationTests.Infrastructure;

namespace Schedule.IntegrationTests.Endpoints;

public class OfficeHoursEndpointsTests(ScheduleApiFactory factory) : IClassFixture<ScheduleApiFactory>
{
    private const string Route = "/api/schedule/office-hours";

    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Create_WithValidRequest_Returns201WithLocation()
    {
        var request = new CreateOfficeHourRequest(
            Guid.NewGuid(), Guid.NewGuid(), DayOfWeek.Monday, new TimeOnly(9, 0), new TimeOnly(11, 0));

        var response = await _client.PostAsJsonAsync(Route, request);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<OfficeHourDto>();
        Assert.NotNull(created);
        Assert.Equal("Monday", created.DayOfWeek);
        Assert.Equal(request.StructureRefId, created.StructureRefId);
        Assert.EndsWith($"{Route}/{created.Id}", response.Headers.Location?.ToString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Create_WhenEndIsNotAfterStart_Returns400()
    {
        var request = new CreateOfficeHourRequest(
            Guid.NewGuid(), null, DayOfWeek.Monday, new TimeOnly(11, 0), new TimeOnly(9, 0));

        var response = await _client.PostAsJsonAsync(Route, request);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetById_WhenOfficeHourExists_Returns200()
    {
        var created = await CreateAsync(Guid.NewGuid(), DayOfWeek.Tuesday);

        var response = await _client.GetAsync($"{Route}/{created.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var found = await response.Content.ReadFromJsonAsync<OfficeHourDto>();
        Assert.Equal(created.Id, found?.Id);
    }

    [Fact]
    public async Task GetById_WhenOfficeHourDoesNotExist_Returns404()
    {
        var response = await _client.GetAsync($"{Route}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetByTeacher_ReturnsOnlyThatTeachersBlocksOrderedByDay()
    {
        var teacherId = Guid.NewGuid();
        await CreateAsync(teacherId, DayOfWeek.Wednesday);
        await CreateAsync(teacherId, DayOfWeek.Monday);
        await CreateAsync(Guid.NewGuid(), DayOfWeek.Monday);

        var blocks = await _client.GetFromJsonAsync<List<OfficeHourDto>>($"{Route}?teacherId={teacherId}");

        Assert.NotNull(blocks);
        Assert.Equal(2, blocks.Count);
        Assert.Equal("Monday", blocks[0].DayOfWeek);
        Assert.Equal("Wednesday", blocks[1].DayOfWeek);
    }

    [Fact]
    public async Task GetAll_WithoutTeacherId_ReturnsBlocksFromEveryTeacher()
    {
        var first = await CreateAsync(Guid.NewGuid(), DayOfWeek.Monday);
        var second = await CreateAsync(Guid.NewGuid(), DayOfWeek.Thursday);

        var blocks = await _client.GetFromJsonAsync<List<OfficeHourDto>>(Route);

        Assert.NotNull(blocks);
        Assert.Contains(blocks, b => b.Id == first.Id);
        Assert.Contains(blocks, b => b.Id == second.Id);
    }

    [Fact]
    public async Task GetByTeacher_OrdersBlocksByWeekdayStartingOnMonday()
    {
        var teacherId = Guid.NewGuid();
        await CreateAsync(teacherId, DayOfWeek.Sunday);
        await CreateAsync(teacherId, DayOfWeek.Friday);
        await CreateAsync(teacherId, DayOfWeek.Monday);

        var blocks = await _client.GetFromJsonAsync<List<OfficeHourDto>>($"{Route}?teacherId={teacherId}");

        Assert.Equal(["Monday", "Friday", "Sunday"], blocks!.Select(b => b.DayOfWeek));
    }

    [Fact]
    public async Task Get_WithEmptyTeacherId_Returns400()
    {
        var response = await _client.GetAsync($"{Route}?teacherId={Guid.Empty}");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    private async Task<OfficeHourDto> CreateAsync(Guid teacherId, DayOfWeek day)
    {
        var request = new CreateOfficeHourRequest(teacherId, null, day, new TimeOnly(9, 0), new TimeOnly(11, 0));
        var response = await _client.PostAsJsonAsync(Route, request);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<OfficeHourDto>())!;
    }
}
