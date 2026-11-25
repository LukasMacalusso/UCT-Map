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
    private const string CategoryEndpoint = "/api/campus/categories";

    public StructureEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<(Guid campusId, Guid categoryId)> SetupDependenciesAsync()
    {
        var campusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus For Structure", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var catRes = await Http.PostAsync(CategoryEndpoint, JsonBody(new CreateCategoryDto("Categoria For Structure", "icon", "desc")));
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
    public async Task Post_WhenCategoryIdIsNull_CreatesStructureAndReturns201()
    {
        var campusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus No Cat", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var body = new CreateStructureDto(campus!.Id, null, "Punto Verde", -38.7, -72.5);
        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<StructureDto>(response);
        Assert.NotNull(created);
        Assert.Equal("Punto Verde", created.Name);
        Assert.Null(created.CategoryId);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await ReadJsonAsync<StructureDto>(getRes);
        Assert.Null(fetched!.CategoryId);
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

        var response = await Http.GetAsync($"{Endpoint}/locations?campusId={campusId}&categoryId={categoryId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<StructureLocationDto>>(response);
        Assert.NotNull(list);
        var structure = Assert.Single(list);
        Assert.Equal("Categoria For Structure", structure.Metadata.CategoryName);
        Assert.Equal("icon", structure.Metadata.CategoryIcon);
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

    [DockerFact]
    public async Task PostAndPut_WhenCampusOrCategoryDoesNotExist_Return400BadRequest()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Estructura Base", -38.7, -72.5)));
        var structure = await ReadJsonAsync<StructureDto>(createRes);

        var postMissingCampus = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(Guid.NewGuid(), categoryId, "Sin Campus", -38.7, -72.5)));
        var postMissingCategory = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, Guid.NewGuid(), "Sin Cat", -38.7, -72.5)));
        var putMissingCampus = await Http.PutAsync($"{Endpoint}/{structure!.Id}", JsonBody(new UpdateStructureDto(Guid.NewGuid(), categoryId, "Sin Campus", -38.7, -72.5)));
        var putMissingCategory = await Http.PutAsync($"{Endpoint}/{structure.Id}", JsonBody(new UpdateStructureDto(campusId, Guid.NewGuid(), "Sin Cat", -38.7, -72.5)));

        Assert.Equal(HttpStatusCode.BadRequest, postMissingCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postMissingCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putMissingCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putMissingCategory.StatusCode);
    }

    [DockerFact]
    public async Task Endpoints_WhenStructureDoesNotExist_Return404NotFound()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var nonExistentId = Guid.NewGuid();

        var getRes = await Http.GetAsync($"{Endpoint}/{nonExistentId}");
        var putRes = await Http.PutAsync($"{Endpoint}/{nonExistentId}", JsonBody(new UpdateStructureDto(campusId, categoryId, "No Existe", 0, 0)));
        var patchRes = await Http.PatchAsync($"{Endpoint}/{nonExistentId}/location", JsonBody(new UpdateLocationDto(-38.7, -72.5)));
        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{nonExistentId}");

        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putRes.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, patchRes.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deleteRes.StatusCode);
    }

    [DockerFact]
    public async Task GetAllAndGetLocations_FilterCombinationsEmptyCampusAndInvalidGuids()
    {
        var (campusId, categoryId) = await SetupDependenciesAsync();
        var emptyCampusRes = await Http.PostAsync(CampusEndpoint, JsonBody(new CreateCampusDto("Campus Vacio Estructuras", "Dir", 0, 0)));
        var emptyCampus = await ReadJsonAsync<CampusDto>(emptyCampusRes);

        await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, categoryId, "Estructura Filtrada", -38.7, -72.5)));

        var byCampusOnly = await ReadJsonAsync<List<StructureDto>>(await Http.GetAsync($"{Endpoint}?campusId={campusId}"));
        var byCategoryOnly = await ReadJsonAsync<List<StructureDto>>(await Http.GetAsync($"{Endpoint}?categoryId={categoryId}"));
        var emptyLocations = await ReadJsonAsync<List<StructureLocationDto>>(await Http.GetAsync($"{Endpoint}/locations?campusId={emptyCampus!.Id}"));

        Assert.Single(byCampusOnly!);
        Assert.Single(byCategoryOnly!);
        Assert.Empty(emptyLocations!);

        var badAllCampus = await Http.GetAsync($"{Endpoint}?campusId={Guid.Empty}");
        var badAllCategory = await Http.GetAsync($"{Endpoint}?categoryId={Guid.Empty}");
        var badLocCampus = await Http.GetAsync($"{Endpoint}/locations?campusId={Guid.Empty}");
        var badLocCategory = await Http.GetAsync($"{Endpoint}/locations?categoryId={Guid.Empty}");

        Assert.Equal(HttpStatusCode.BadRequest, badAllCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, badAllCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, badLocCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, badLocCategory.StatusCode);
    }

    [DockerFact]
    public async Task Post_Put_PatchLocation_WhenEmptyGuidsOrOutOfRange_Return400BadRequest()
    {
        var (campusId, _) = await SetupDependenciesAsync();
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, null, "Estructura Reglas", -38.7, -72.5)));
        var structure = await ReadJsonAsync<StructureDto>(createRes);

        var postEmptyCampus = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(Guid.Empty, null, "Nombre", -38.7, -72.5)));
        var postEmptyCategory = await Http.PostAsync(Endpoint, JsonBody(new CreateStructureDto(campusId, Guid.Empty, "Nombre", -38.7, -72.5)));
        var putEmptyCampus = await Http.PutAsync($"{Endpoint}/{structure!.Id}", JsonBody(new UpdateStructureDto(Guid.Empty, null, "Nombre", -38.7, -72.5)));
        var putEmptyCategory = await Http.PutAsync($"{Endpoint}/{structure.Id}", JsonBody(new UpdateStructureDto(campusId, Guid.Empty, "Nombre", -38.7, -72.5)));
        var patchOutOfRange = await Http.PatchAsync($"{Endpoint}/{structure.Id}/location", JsonBody(new UpdateLocationDto(95.0, -72.5)));

        Assert.Equal(HttpStatusCode.BadRequest, postEmptyCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postEmptyCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putEmptyCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putEmptyCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, patchOutOfRange.StatusCode);
    }
}
