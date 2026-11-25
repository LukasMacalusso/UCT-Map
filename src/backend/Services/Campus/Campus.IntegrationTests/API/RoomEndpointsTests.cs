using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class RoomEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/campus/rooms";
    private const string CampusEndpoint = "/api/campus/campuses";
    private const string BuildingEndpoint = "/api/campus/buildings";

    public RoomEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<Guid> SetupBuildingAsync()
    {
        var campusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus For Rooms", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var buildingRes = await Http.PostAsync(BuildingEndpoint, JsonBody(new CreateBuildingDto(campus!.Id, "Edificio For Rooms", 3, 0, 0)));
        var building = await ReadJsonAsync<BuildingDto>(buildingRes);

        return building!.Id;
    }

    [DockerFact]
    public async Task Post_WhenDependenciesExist_CreatesRoomAndReturns201()
    {
        var buildingId = await SetupBuildingAsync();
        var body = new CreateRoomDto(buildingId, "101 E2E", 1);

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<RoomDto>(response);
        Assert.NotNull(created);
        Assert.Equal("101 E2E", created.Name);
        Assert.Equal(buildingId, created.BuildingId);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [DockerFact]
    public async Task GetAll_ReturnsListOfRooms()
    {
        var buildingId = await SetupBuildingAsync();
        var body = new CreateRoomDto(buildingId, "SPL-1", 1);
        await Http.PostAsync(Endpoint, JsonBody(body));

        var response = await Http.GetAsync(Endpoint);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<RoomDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task SearchAndGetByBuilding_ReturnsRooms()
    {
        var buildingId = await SetupBuildingAsync();
        var body = new CreateRoomDto(buildingId, "Auditorio", 1);
        await Http.PostAsync(Endpoint, JsonBody(body));

        var searchRes = await Http.GetAsync($"{Endpoint}/search?term=Auditorio");
        Assert.Equal(HttpStatusCode.OK, searchRes.StatusCode);
        var searchList = await ReadJsonAsync<List<RoomDto>>(searchRes);
        Assert.NotEmpty(searchList!);

        var byBuildingRes = await Http.GetAsync($"/api/campus/buildings/{buildingId}/rooms");
        Assert.Equal(HttpStatusCode.OK, byBuildingRes.StatusCode);
        var buildingList = await ReadJsonAsync<List<RoomDto>>(byBuildingRes);
        Assert.NotEmpty(buildingList!);
    }

    [DockerFact]
    public async Task Put_WhenValid_UpdatesRoomAndReturnsNoContent()
    {
        var buildingId = await SetupBuildingAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, "Sala Vieja", 1)));
        var created = await ReadJsonAsync<RoomDto>(createRes);

        var updateBody = new UpdateRoomDto(buildingId, "Sala Nueva", 2);
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<RoomDto>(getRes);
        Assert.Equal("Sala Nueva", fetched!.Name);
        Assert.Equal(2, fetched.Floor);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesRoomAndReturnsNoContent()
    {
        var buildingId = await SetupBuildingAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, "Sala Borrar", 1)));
        var created = await ReadJsonAsync<RoomDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }

    [DockerFact]
    public async Task PostAndPut_WhenBuildingOrRoomDoesNotExist_Return404NotFound()
    {
        var buildingId = await SetupBuildingAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, "Sala Base", 1)));
        var room = await ReadJsonAsync<RoomDto>(createRes);

        var postMissingBuilding = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(Guid.NewGuid(), "Sala Huérfana", 1)));
        var putMissingRoom = await Http.PutAsync($"{Endpoint}/{Guid.NewGuid()}", JsonBody(new UpdateRoomDto(buildingId, "No Existe", 1)));
        var putMissingBuilding = await Http.PutAsync($"{Endpoint}/{room!.Id}", JsonBody(new UpdateRoomDto(Guid.NewGuid(), "Sin Edificio", 1)));
        var getMissingRoom = await Http.GetAsync($"{Endpoint}/{Guid.NewGuid()}");
        var deleteMissingRoom = await Http.DeleteAsync($"{Endpoint}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, postMissingBuilding.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putMissingRoom.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putMissingBuilding.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, getMissingRoom.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deleteMissingRoom.StatusCode);
    }

    [DockerFact]
    public async Task GetAll_Post_Put_WhenInvalidParameters_Return400BadRequest()
    {
        var buildingId = await SetupBuildingAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, "Sala Reglas", 1)));
        var room = await ReadJsonAsync<RoomDto>(createRes);

        var emptyBuildingFilter = await Http.GetAsync($"{Endpoint}?buildingId={Guid.Empty}");
        var postEmptyBuilding = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(Guid.Empty, "Sala", 1)));
        var postZeroFloor = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, "Sala", 0)));
        var putEmptyBuilding = await Http.PutAsync($"{Endpoint}/{room!.Id}", JsonBody(new UpdateRoomDto(Guid.Empty, "Sala", 1)));

        Assert.Equal(HttpStatusCode.BadRequest, emptyBuildingFilter.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postEmptyBuilding.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postZeroFloor.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putEmptyBuilding.StatusCode);
    }

    [DockerFact]
    public async Task SearchAndFilterByBuilding_HandleWhitespaceAndCaseInsensitivity()
    {
        var buildingId = await SetupBuildingAsync();
        var uniqueRoomName = $"LAB-{Guid.NewGuid().ToString("N")[..8].ToUpperInvariant()}";
        await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, uniqueRoomName, 2)));

        var emptySearchRes = await Http.GetAsync($"{Endpoint}/search?term=%20%20%20");
        Assert.Equal(HttpStatusCode.OK, emptySearchRes.StatusCode);
        var emptyList = await ReadJsonAsync<List<RoomDto>>(emptySearchRes);
        Assert.Empty(emptyList!);

        var caseInsensitiveRes = await Http.GetAsync($"{Endpoint}/search?term=%20{uniqueRoomName.ToLowerInvariant()}%20");
        Assert.Equal(HttpStatusCode.OK, caseInsensitiveRes.StatusCode);
        var matches = await ReadJsonAsync<List<RoomDto>>(caseInsensitiveRes);
        var matched = Assert.Single(matches!);
        Assert.Equal(uniqueRoomName, matched.Name);

        var byBuildingQueryRes = await Http.GetAsync($"{Endpoint}?buildingId={buildingId}");
        var byBuildingList = await ReadJsonAsync<List<RoomDto>>(byBuildingQueryRes);
        var singleInBuilding = Assert.Single(byBuildingList!);
        Assert.Equal(uniqueRoomName, singleInBuilding.Name);
    }
}
