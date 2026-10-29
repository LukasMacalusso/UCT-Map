using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class StructureEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/campus/structures";
    private const string CampusEndpoint = "/api/campus/campuses";
    private const string GroupEndpoint = "/api/campus/category-groups";
    private const string CategoryEndpoint = "/api/campus/categories";

    public StructureEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<(Guid campusId, Guid categoryId)> SetupDependenciesAsync()
    {
        var campusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus For Structure", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var groupRes = await Http.PostAsync(GroupEndpoint, JsonBody(new CreateCategoryGroupDto("Grupo For Structure")));
        var group = await ReadJsonAsync<CategoryGroupDto>(groupRes);

        var catRes = await Http.PostAsync(CategoryEndpoint, JsonBody(new CreateCategoryDto(group!.Id, "Categoria For Structure", "icon", "desc")));
        var cat = await ReadJsonAsync<CategoryDto>(catRes);

        return (campus!.Id, cat!.Id);
    }

    [DockerFact]
    public async Task Post_WhenDependenciesExist_CreatesStructureAndReturns201()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var body = new CreateStructureDto(campusId, categoryId, "Pérgola Norte", -38.7, -72.5);

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<StructureDto>(response);
        Assert.NotNull(created);
        Assert.Equal("Pérgola Norte", created.Name);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
    }

    [DockerFact]
    public async Task GetAll_ReturnsListOfStructures()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Cancha", -38.7, -72.5)));

        var response = await Http.GetAsync(Endpoint);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<StructureDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task Put_WhenValid_UpdatesStructureAndReturnsNoContent()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Original", 0, 0)));
        var created = await ReadJsonAsync<StructureDto>(createRes);

        var updateBody = new UpdateStructureDto(campusId, categoryId, "Actualizada", 1, 2);
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<StructureDto>(getRes);
        Assert.Equal("Actualizada", fetched!.Name);
    }

    [DockerFact]
    public async Task GetLocations_ReturnsLocationsOfStructures()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Estructura Mapa", -38.7, -72.5)));

        var response = await Http.GetAsync($"{Endpoint}/locations");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<StructureLocationDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task PatchLocation_WhenValid_UpdatesCoordinatesAndReturnsNoContent()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Estructura Patch", 0, 0)));
        var created = await ReadJsonAsync<StructureDto>(createRes);

        var patchBody = new UpdateLocationDto(-38.75, -72.62);
        var patchRes = await Http.PatchAsync($"{Endpoint}/{created!.Id}/location", JsonBody(patchBody));
        Assert.Equal(HttpStatusCode.NoContent, patchRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<StructureDto>(getRes);
        Assert.Equal(-38.75, fetched!.Latitude);
        Assert.Equal(-72.62, fetched.Longitude);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesStructureAndReturnsNoContent()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Borrar", 0, 0)));
        var created = await ReadJsonAsync<StructureDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }
}
