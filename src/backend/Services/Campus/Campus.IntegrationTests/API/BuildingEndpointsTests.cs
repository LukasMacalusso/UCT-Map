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
        var body = new CreateBuildingDto(
            campusId,
            "Edificio Locations",
            3,
            -38.736,
            -72.596,
            new TimeOnly(8, 0),
            new TimeOnly(20, 0)
        );
        await Http.PostAsync(Endpoint, JsonBody(body));

        var response = await Http.GetAsync($"{Endpoint}/locations?campusId={campusId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<BuildingLocationDto>>(response);
        Assert.NotNull(list);
        var building = Assert.Single(list);
        Assert.Equal("08:00 - 20:00", building.Metadata.Schedule);
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
    public async Task PatchLocation_WhenValid_UpdatesCoordinatesAndReturnsNoContent()
    {
        var campusId = await CreateCampusHelperAsync("Campus Para Patch Location");
        var createBody = new CreateBuildingDto(campusId, "Edificio Coordenadas", 2, -38.73, -72.59);
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<BuildingDto>(createRes);

        var patchBody = new UpdateLocationDto(-38.745, -72.615);
        var patchRes = await Http.PatchAsync($"{Endpoint}/{created!.Id}/location", JsonBody(patchBody));
        Assert.Equal(HttpStatusCode.NoContent, patchRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<BuildingDto>(getRes);
        Assert.Equal(-38.745, fetched!.Latitude);
        Assert.Equal(-72.615, fetched.Longitude);
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

    [DockerFact]
    public async Task GetAll_SupportsCampusAndCategoryFiltersAndEnrichesCategoryMetadata()
    {
        var campusId = await CreateCampusHelperAsync("Campus Filtro Edificios");
        var catRes = await Http.PostAsync("/api/campus/categories", JsonBody(new CreateCategoryDto("Facultad Test", "faculty-icon", "Docencia")));
        var category = await ReadJsonAsync<CategoryDto>(catRes);

        var withCatRes = await Http.PostAsync(
            Endpoint,
            JsonBody(new CreateBuildingDto(campusId, "Edificio Categorizado", 3, -38.73, -72.59, null, null, category!.Id, "https://uct.cl/foto.jpg")));
        var withCat = await ReadJsonAsync<BuildingDto>(withCatRes);

        await Http.PostAsync(
            Endpoint,
            JsonBody(new CreateBuildingDto(campusId, "Edificio Sin Categoria", 2, -38.74, -72.60)));

        var allRes = await Http.GetAsync(Endpoint);
        Assert.Equal(HttpStatusCode.OK, allRes.StatusCode);
        var allBuildings = await ReadJsonAsync<List<BuildingDto>>(allRes);
        Assert.Contains(allBuildings!, b => b.Id == withCat!.Id && b.CategoryName == "Facultad Test" && b.CategoryIcon == "faculty-icon");

        var byCampusRes = await Http.GetAsync($"{Endpoint}?campusId={campusId}");
        var byCampus = await ReadJsonAsync<List<BuildingDto>>(byCampusRes);
        Assert.Equal(2, byCampus!.Count);

        var byBothRes = await Http.GetAsync($"{Endpoint}?campusId={campusId}&categoryId={category.Id}");
        var byBoth = await ReadJsonAsync<List<BuildingDto>>(byBothRes);
        var filtered = Assert.Single(byBoth!);
        Assert.Equal(withCat!.Id, filtered.Id);
        Assert.Equal("https://uct.cl/foto.jpg", filtered.PhotoUrl);
    }

    [DockerFact]
    public async Task GetAllAndGetLocations_WhenQueryFilterIsEmptyGuid_Return400BadRequest()
    {
        var emptyCampusAll = await Http.GetAsync($"{Endpoint}?campusId={Guid.Empty}");
        var emptyCategoryAll = await Http.GetAsync($"{Endpoint}?categoryId={Guid.Empty}");
        var emptyCampusLoc = await Http.GetAsync($"{Endpoint}/locations?campusId={Guid.Empty}");
        var emptyCategoryLoc = await Http.GetAsync($"{Endpoint}/locations?categoryId={Guid.Empty}");

        Assert.Equal(HttpStatusCode.BadRequest, emptyCampusAll.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, emptyCategoryAll.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, emptyCampusLoc.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, emptyCategoryLoc.StatusCode);
    }

    [DockerFact]
    public async Task GetLocations_WithPartialSchedules_FormatsOpenOnlyAndCloseOnlyCorrectly()
    {
        var campusId = await CreateCampusHelperAsync("Campus Horarios Parciales");

        await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Solo Apertura", 1, -38.73, -72.59, new TimeOnly(7, 30), null)));
        await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Solo Cierre", 1, -38.74, -72.60, null, new TimeOnly(21, 15))));
        await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Sin Horario", 1, -38.75, -72.61, null, null)));

        var response = await Http.GetAsync($"{Endpoint}/locations?campusId={campusId}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<BuildingLocationDto>>(response);

        Assert.Contains(list!, b => b.Name == "Solo Apertura" && b.Metadata.Schedule == "07:30");
        Assert.Contains(list!, b => b.Name == "Solo Cierre" && b.Metadata.Schedule == "21:15");
        Assert.Contains(list!, b => b.Name == "Sin Horario" && b.Metadata.Schedule == null);
    }

    [DockerFact]
    public async Task Delete_WhenBuildingHasRooms_Returns409ConflictAndPreservesBuilding()
    {
        var campusId = await CreateCampusHelperAsync("Campus Edificio Con Salas");
        var buildingRes = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Edificio Con Sala", 3, -38.73, -72.59)));
        var building = await ReadJsonAsync<BuildingDto>(buildingRes);

        await Http.PostAsync("/api/campus/rooms", JsonBody(new CreateRoomDto(building!.Id, "LAB-101", 1)));

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{building.Id}");

        Assert.Equal(HttpStatusCode.Conflict, deleteRes.StatusCode);

        var checkRes = await Http.GetAsync($"{Endpoint}/{building.Id}");
        Assert.Equal(HttpStatusCode.OK, checkRes.StatusCode);
    }

    [DockerFact]
    public async Task PostAndPut_WhenForeignKeysOrTargetDoNotExist_Return404NotFound()
    {
        var campusId = await CreateCampusHelperAsync("Campus FK Edificios");
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Edificio Valido", 2, -38.73, -72.59)));
        var building = await ReadJsonAsync<BuildingDto>(createRes);

        var postMissingCampus = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(Guid.NewGuid(), "Sin Campus", 2, -38.73, -72.59)));
        var postMissingCategory = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Sin Cat", 2, -38.73, -72.59, null, null, Guid.NewGuid())));

        var putMissingBuilding = await Http.PutAsync($"{Endpoint}/{Guid.NewGuid()}", JsonBody(new UpdateBuildingDto(campusId, "No Existe", 2, -38.73, -72.59)));
        var putMissingCampus = await Http.PutAsync($"{Endpoint}/{building!.Id}", JsonBody(new UpdateBuildingDto(Guid.NewGuid(), "Sin Campus", 2, -38.73, -72.59)));
        var putMissingCategory = await Http.PutAsync($"{Endpoint}/{building.Id}", JsonBody(new UpdateBuildingDto(campusId, "Sin Cat", 2, -38.73, -72.59, null, null, Guid.NewGuid())));

        var patchMissing = await Http.PatchAsync($"{Endpoint}/{Guid.NewGuid()}/location", JsonBody(new UpdateLocationDto(-38.7, -72.6)));
        var deleteMissing = await Http.DeleteAsync($"{Endpoint}/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, postMissingCampus.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, postMissingCategory.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putMissingBuilding.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putMissingCampus.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putMissingCategory.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, patchMissing.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deleteMissing.StatusCode);
    }

    [DockerFact]
    public async Task PostAndPut_WhenBusinessConstraintsViolated_Return400BadRequest()
    {
        var campusId = await CreateCampusHelperAsync("Campus Reglas Edificio");
        var createRes = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Edificio Base", 2, -38.73, -72.59)));
        var building = await ReadJsonAsync<BuildingDto>(createRes);

        var postEmptyCampus = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(Guid.Empty, "Nombre", 2, -38.73, -72.59)));
        var postEmptyCategory = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Nombre", 2, -38.73, -72.59, null, null, Guid.Empty)));
        var postEqualSchedule = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Horario Igual", 2, -38.73, -72.59, new TimeOnly(8, 0), new TimeOnly(8, 0))));
        var postInvertedSchedule = await Http.PostAsync(Endpoint, JsonBody(new CreateBuildingDto(campusId, "Horario Invertido", 2, -38.73, -72.59, new TimeOnly(20, 0), new TimeOnly(8, 0))));

        var putEmptyCampus = await Http.PutAsync($"{Endpoint}/{building!.Id}", JsonBody(new UpdateBuildingDto(Guid.Empty, "Nombre", 2, -38.73, -72.59)));
        var putEmptyCategory = await Http.PutAsync($"{Endpoint}/{building.Id}", JsonBody(new UpdateBuildingDto(campusId, "Nombre", 2, -38.73, -72.59, null, null, Guid.Empty)));
        var putInvertedSchedule = await Http.PutAsync($"{Endpoint}/{building.Id}", JsonBody(new UpdateBuildingDto(campusId, "Horario Invertido", 2, -38.73, -72.59, new TimeOnly(22, 0), new TimeOnly(7, 0))));

        Assert.Equal(HttpStatusCode.BadRequest, postEmptyCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postEmptyCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postEqualSchedule.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, postInvertedSchedule.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putEmptyCampus.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putEmptyCategory.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, putInvertedSchedule.StatusCode);
    }
}
