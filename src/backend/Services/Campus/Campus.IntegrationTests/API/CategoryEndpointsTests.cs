using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class CategoryEndpointsTests : ApiTestBase
{
    private const string Endpoint = "/api/campus/categories";

    public CategoryEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    [DockerFact]
    public async Task Post_WhenRequestIsValid_CreatesCategoryAndReturns201()
    {
        var body = new CreateCategoryDto("Laboratorios E2E", "lab-icon", "Laboratorios de computación");

        var response = await Http.PostAsync(Endpoint, JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await ReadJsonAsync<CategoryDto>(response);
        Assert.NotNull(created);
        Assert.Equal("Laboratorios E2E", created.Name);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.OK, getRes.StatusCode);
        var fetched = await ReadJsonAsync<CategoryDto>(getRes);
        Assert.Equal(created.Id, fetched!.Id);
    }

    [DockerFact]
    public async Task GetAll_ReturnsListOfCategories()
    {
        var body = new CreateCategoryDto("Aulas E2E", "room-icon", "Salas normales");
        await Http.PostAsync(Endpoint, JsonBody(body));

        var response = await Http.GetAsync(Endpoint);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var list = await ReadJsonAsync<List<CategoryDto>>(response);
        Assert.NotNull(list);
        Assert.NotEmpty(list);
    }

    [DockerFact]
    public async Task Put_WhenValid_UpdatesCategoryAndReturnsNoContent()
    {
        var createBody = new CreateCategoryDto("Cat Original", "icon1", "desc1");
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CategoryDto>(createRes);

        var updateBody = new UpdateCategoryDto("Cat Editada", "icon2", "desc2");
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<CategoryDto>(getRes);
        Assert.Equal("Cat Editada", fetched!.Name);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesCategoryAndReturnsNoContent()
    {
        var createBody = new CreateCategoryDto("Cat Para Borrar", "icon", "desc");
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CategoryDto>(createRes);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{created!.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
    }

    [DockerFact]
    public async Task Put_Reorder_WhenValid_UpdatesCategoriesOrderAndReturnsNoContent()
    {
        var cat1Res = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto("Cat Reorder 1", "icon1", "desc", 0)));
        var cat1 = await ReadJsonAsync<CategoryDto>(cat1Res);
        var cat2Res = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto("Cat Reorder 2", "icon2", "desc", 1)));
        var cat2 = await ReadJsonAsync<CategoryDto>(cat2Res);

        var reorderItems = new List<ReorderItemDto>
        {
            new(cat1!.Id, 10),
            new(cat2!.Id, 5)
        };

        var reorderRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(reorderItems));
        Assert.Equal(HttpStatusCode.NoContent, reorderRes.StatusCode);

        var getCat1 = await Http.GetAsync($"{Endpoint}/{cat1.Id}");
        var cat1Fetched = await ReadJsonAsync<CategoryDto>(getCat1);
        Assert.Equal(10, cat1Fetched!.Order);

        var getCat2 = await Http.GetAsync($"{Endpoint}/{cat2.Id}");
        var cat2Fetched = await ReadJsonAsync<CategoryDto>(getCat2);
        Assert.Equal(5, cat2Fetched!.Order);
    }

    [DockerFact]
    public async Task Delete_WhenCategoryHasStructures_DeletesCategoryAndSetsStructureCategoryToNull()
    {
        var campusRes = await Http.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Campus For Null FK", "Dir", 0, 0)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var catRes = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto("Cat Con Estructuras", "icon", "desc")));
        var cat = await ReadJsonAsync<CategoryDto>(catRes);

        var structRes = await Http.PostAsync("/api/campus/structures", JsonBody(new CreateStructureDto(campus!.Id, cat!.Id, "Estructura En Categoria", -38.7, -72.5)));
        var structure = await ReadJsonAsync<StructureDto>(structRes);
        Assert.NotNull(structure);
        Assert.Equal(cat.Id, structure.CategoryId);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{cat.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getStructRes = await Http.GetAsync($"/api/campus/structures/{structure.Id}");
        Assert.Equal(HttpStatusCode.OK, getStructRes.StatusCode);
        var structureAfterDelete = await ReadJsonAsync<StructureDto>(getStructRes);
        Assert.NotNull(structureAfterDelete);
        Assert.Null(structureAfterDelete.CategoryId);
    }

    [DockerFact]
    public async Task Delete_WhenCategoryHasBuildings_DeletesCategoryAndSetsBuildingCategoryToNull()
    {
        var campusRes = await Http.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Campus Building Null FK", "Dir", -38.7, -72.5)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var catRes = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto("Cat Con Edificios", "building-icon", "desc")));
        var cat = await ReadJsonAsync<CategoryDto>(catRes);

        var buildingRes = await Http.PostAsync(
            "/api/campus/buildings",
            JsonBody(new CreateBuildingDto(campus!.Id, "Edificio En Categoria", 3, -38.7, -72.5, null, null, cat!.Id)));
        var building = await ReadJsonAsync<BuildingDto>(buildingRes);
        Assert.Equal(cat.Id, building!.CategoryId);

        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{cat.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteRes.StatusCode);

        var getBuildingRes = await Http.GetAsync($"/api/campus/buildings/{building.Id}");
        Assert.Equal(HttpStatusCode.OK, getBuildingRes.StatusCode);
        var buildingAfterDelete = await ReadJsonAsync<BuildingDto>(getBuildingRes);
        Assert.NotNull(buildingAfterDelete);
        Assert.Null(buildingAfterDelete.CategoryId);
    }

    [DockerFact]
    public async Task Endpoints_WhenCategoryDoesNotExist_Return404NotFound()
    {
        var nonExistentId = Guid.NewGuid();

        var getRes = await Http.GetAsync($"{Endpoint}/{nonExistentId}");
        var putRes = await Http.PutAsync($"{Endpoint}/{nonExistentId}", JsonBody(new UpdateCategoryDto("Inexistente", "icon", "desc")));
        var deleteRes = await Http.DeleteAsync($"{Endpoint}/{nonExistentId}");

        Assert.Equal(HttpStatusCode.NotFound, getRes.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, putRes.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, deleteRes.StatusCode);
    }

    [DockerFact]
    public async Task Put_Reorder_WhenInvalidPayload_Returns400AndPreservesExistingOrder()
    {
        var catRes = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto("Cat Orden Intacto", "icon", "desc", 7)));
        var cat = await ReadJsonAsync<CategoryDto>(catRes);

        var emptyRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(new List<ReorderItemDto>()));
        var emptyGuidRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(new List<ReorderItemDto> { new(Guid.Empty, 1) }));
        var negativeOrderRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(new List<ReorderItemDto> { new(cat!.Id, -3) }));
        var duplicateRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(new List<ReorderItemDto> { new(cat.Id, 1), new(cat.Id, 2) }));
        var missingCategoryRes = await Http.PutAsync($"{Endpoint}/reorder", JsonBody(new List<ReorderItemDto> { new(cat.Id, 99), new(Guid.NewGuid(), 2) }));

        Assert.Equal(HttpStatusCode.BadRequest, emptyRes.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, emptyGuidRes.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, negativeOrderRes.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, duplicateRes.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, missingCategoryRes.StatusCode);

        var fetched = await ReadJsonAsync<CategoryDto>(await Http.GetAsync($"{Endpoint}/{cat.Id}"));
        Assert.Equal(7, fetched!.Order);
    }
}
