using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class BuildingEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/campus/buildings";
    private const string CampusEndpoint = "/api/campus/campuses";

    public BuildingEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<Guid> CreateCampusHelperAsync(string name)
    {
        var body = new CreateCampusDto(name, "Dirección", -38.73, -72.59);
        var res = await Http.PostAsync(CampusEndpoint, JsonBody(body));
        var created = await ReadJsonAsync<CampusDto>(res);
        return created!.Id;
    }

    [DockerFact]
    public async Task Post_WhenCampusExists_CreatesBuildingAndReturns201()
    {
        var campusId = await CreateCampusHelperAsync("Campus Para Edificio");
        var body = new CreateBuildingDto(campusId, "Edificio de Informática", 4, -38.735, -72.595);

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<BuildingDto>(response);
        Assert.NotNull(created);
        Assert.Equal("Edificio de Informática", created.Name);
        Assert.Equal(campusId, created.CampusId);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [DockerFact]
    public async Task GetLocations_ReturnsLocationsOfBuildings()
    {
        var campusId = await CreateCampusHelperAsync("Campus Para Locations");
        var body = new CreateBuildingDto(campusId, "Edificio Locations", 3, -38.736, -72.596);
        await Http.PostAsync(Endpoint, JsonBody(body));

        var response = await Http.GetAsync($"{Endpoint}/locations");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<BuildingLocationDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task Put_WhenValid_UpdatesBuildingAndReturnsNoContent()
    {
        var campusId = await CreateCampusHelperAsync("Campus Para Put");
        var createBody = new CreateBuildingDto(campusId, "Edificio Antiguo", 2, -38.73, -72.59);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<BuildingDto>(createRes);

        var updateBody = new UpdateBuildingDto(campusId, "Edificio Renovado", 5, -38.74, -72.60);
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<BuildingDto>(getRes);
        Assert.Equal("Edificio Renovado", fetched!.Name);
        Assert.Equal(5, fetched.FloorsCount);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesBuildingAndReturnsNoContent()
    {
        var campusId = await CreateCampusHelperAsync("Campus Para Delete");
        var createBody = new CreateBuildingDto(campusId, "Edificio A Borrar", 1, -38.73, -72.59);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<BuildingDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }
}
