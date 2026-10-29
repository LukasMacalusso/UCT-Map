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
    private const string GroupEndpoint = "/api/campus/category-groups";
    private const string CategoryEndpoint = "/api/campus/categories";

    public RoomEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<(Guid buildingId, Guid categoryId)> SetupDependenciesAsync()
    {
        var campusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus For Rooms", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var buildingRes = await Http.PostAsync(BuildingEndpoint, JsonBody(new CreateBuildingDto(campus!.Id, "Edificio For Rooms", 3, 0, 0)));
        var building = await ReadJsonAsync<BuildingDto>(buildingRes);

        var groupRes = await Http.PostAsync(GroupEndpoint, JsonBody(new CreateCategoryGroupDto("Grupo For Rooms")));
        var group = await ReadJsonAsync<CategoryGroupDto>(groupRes);

        var catRes = await Http.PostAsync(CategoryEndpoint, JsonBody(new CreateCategoryDto(group!.Id, "Categoria For Rooms", "icon", "desc")));
        var cat = await ReadJsonAsync<CategoryDto>(catRes);

        return (building!.Id, cat!.Id);
    }

    [DockerFact]
    public async Task Post_WhenDependenciesExist_CreatesRoomAndReturns201()
    {
        var (buildingId, categoryId) = await SetupDependenciesAsync();
        var body = new CreateRoomDto(buildingId, categoryId, "101 E2E", 1);

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<RoomDto>(response);
        Assert.NotNull(created);
        Assert.Equal("101 E2E", created.Name);
        Assert.Equal(buildingId, created.BuildingId);
        Assert.Equal(categoryId, created.CategoryId);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [DockerFact]
    public async Task GetAll_ReturnsListOfRooms()
    {
        var (buildingId, categoryId) = await SetupDependenciesAsync();
        var body = new CreateRoomDto(buildingId, categoryId, "SPL-1", 1);
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
        var (buildingId, categoryId) = await SetupDependenciesAsync();
        var body = new CreateRoomDto(buildingId, categoryId, "Auditorio", 1);
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
        var (buildingId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, categoryId, "Sala Vieja", 1)));
        var created = await ReadJsonAsync<RoomDto>(createRes);

        var updateBody = new UpdateRoomDto(buildingId, categoryId, "Sala Nueva", 2);
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
        var (buildingId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateRoomDto(buildingId, categoryId, "Sala Borrar", 1)));
        var created = await ReadJsonAsync<RoomDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }
}
