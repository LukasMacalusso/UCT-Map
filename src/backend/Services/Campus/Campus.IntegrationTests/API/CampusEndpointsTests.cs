using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class CampusEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/campus/campuses";

    public CampusEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    [DockerFact]
    public async Task Post_WhenRequestIsValid_CreatesCampusAndReturns201()
    {
        var body = new CreateCampusDto("Campus Norte Test", "Dirección Test 123", -38.73, -72.59);

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<CampusDto>(response);
        Assert.NotNull(created);
        Assert.Equal("Campus Norte Test", created.Name);

        var getResponse = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
        var fetched = await ReadJsonAsync<CampusDto>(getResponse);
        Assert.NotNull(fetched);
        Assert.Equal(created.Id, fetched.Id);
    }

    [DockerFact]
    public async Task GetAll_ReturnsListOfCampuses()
    {
        var body = new CreateCampusDto("Campus Para Listar", "Dir 456", -38.74, -72.60);
        await Http.PostAsync(Endpoint, JsonBody(body));

        var response = await Http.GetAsync(Endpoint);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<CampusDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task Put_WhenValid_UpdatesCampusAndReturnsNoContent()
    {
        var createBody = new CreateCampusDto("Campus Original", "Dir Original", -38.75, -72.61);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CampusDto>(createRes);

        var updateBody = new UpdateCampusDto("Campus Modificado", "Dir Modificada", -38.76, -72.62);
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<CampusDto>(getRes);
        Assert.Equal("Campus Modificado", fetched!.Name);
    }

    [DockerFact]
    public async Task PatchLocation_WhenValid_UpdatesCoordinatesAndReturnsNoContent()
    {
        var createBody = new CreateCampusDto("Campus Para Patch", "Dir Patch", -38.77, -72.63);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CampusDto>(createRes);

        var patchBody = new UpdateLocationDto(-38.80, -72.70);
        var patchRes = await Http.PatchAsync($"{Endpoint}/{created!.Id}/location", JsonBody(patchBody));
        Assert.Equal(HttpStatusCode.NoContent, patchRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<CampusDto>(getRes);
        Assert.Equal(-38.80, fetched!.Latitude);
        Assert.Equal(-72.70, fetched.Longitude);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesCampusAndReturnsNoContent()
    {
        var createBody = new CreateCampusDto("Campus Para Borrar", "Dir Borrar", -38.77, -72.63);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CampusDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }

    [DockerFact]
    public async Task GetMap_WhenCampusExists_ReturnsUnifiedMapPayload()
    {
        var campusRes = await Http.PostAsync(
            Endpoint,
            JsonBody(new CreateCampusDto("Campus Mapa", "Manuel Montt 056", -38.7335, -72.6020, 16.0m, 50.0m, -20.0m))
        );
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var groupRes = await Http.PostAsync("/api/campus/category-groups", JsonBody(new CreateCategoryGroupDto("Espacios Exterior")));
        var group = await ReadJsonAsync<CategoryGroupDto>(groupRes);

        var catRes = await Http.PostAsync("/api/campus/categories", JsonBody(new CreateCategoryDto(group!.Id, "Estacionamiento", "car", "Zona vehicular")));
        var category = await ReadJsonAsync<CategoryDto>(catRes);

        await Http.PostAsync(
            "/api/campus/buildings",
            JsonBody(new CreateBuildingDto(
                campus!.Id,
                "Edificio 16",
                3,
                -38.7336,
                -72.6021,
                new TimeOnly(8, 0),
                new TimeOnly(21, 0),
                "Wifi, Baños"
            ))
        );

        await Http.PostAsync(
            "/api/campus/structures",
            JsonBody(new CreateStructureDto(campus.Id, category!.Id, "Estacionamiento Norte", -38.7338, -72.6025))
        );

        var mapRes = await Http.GetAsync($"{Endpoint}/{campus.Id}/map");

        Assert.Equal(HttpStatusCode.OK, mapRes.StatusCode);
        var map = await ReadJsonAsync<CampusMapDto>(mapRes);
        Assert.NotNull(map);
        Assert.Equal(campus.Id, map.Id);
        Assert.Equal("Campus Mapa", map.Name);
        Assert.Equal(-38.7335, map.Camera.Center.Latitude);
        Assert.Equal(-72.6020, map.Camera.Center.Longitude);
        Assert.Equal(16.0m, map.Camera.Zoom);
        Assert.Equal(50.0m, map.Camera.Pitch);
        Assert.Equal(-20.0m, map.Camera.Bearing);

        var building = Assert.Single(map.Buildings);
        Assert.Equal("Edificio 16", building.Name);
        Assert.Equal("08:00 - 21:00", building.Metadata.Schedule);
        Assert.Equal(new[] { "Wifi", "Baños" }, building.Metadata.Services);

        var structure = Assert.Single(map.Structures);
        Assert.Equal("Estacionamiento Norte", structure.Name);
        Assert.Equal("Estacionamiento", structure.Metadata.CategoryName);
        Assert.Equal("car", structure.Metadata.CategoryIcon);
    }

    [DockerFact]
    public async Task GetMap_WhenCampusDoesNotExist_ReturnsNotFound()
    {
        var mapRes = await Http.GetAsync($"{Endpoint}/{Guid.NewGuid()}/map");

        Assert.Equal(HttpStatusCode.NotFound, mapRes.StatusCode);
    }
}
