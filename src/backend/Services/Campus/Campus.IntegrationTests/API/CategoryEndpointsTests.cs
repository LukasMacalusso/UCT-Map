using System;
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
    private const string GroupEndpoint = "/api/campus/category-groups";

    public CategoryEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    private async Task<Guid> CreateGroupAsync(string name = "Grupo Test")
    {
        var res = await Http.PostAsync(GroupEndpoint, JsonBody(new CreateCategoryGroupDto(name)));
        var group = await ReadJsonAsync<CategoryGroupDto>(res);
        return group!.Id;
    }

    [DockerFact]
    public async Task Post_WhenRequestIsValid_CreatesCategoryAndReturns201()
    {
        var groupId = await CreateGroupAsync();
        var body = new CreateCategoryDto(groupId, "Laboratorios E2E", "lab-icon", "Laboratorios de computación");

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
        var groupId = await CreateGroupAsync();
        var body = new CreateCategoryDto(groupId, "Aulas E2E", "room-icon", "Salas normales");
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
        var groupId = await CreateGroupAsync();
        var createBody = new CreateCategoryDto(groupId, "Cat Original", "icon1", "desc1");
        var createRes = await Http.PostAsync(Endpoint, JsonBody(createBody));
        var created = await ReadJsonAsync<CategoryDto>(createRes);

        var updateBody = new UpdateCategoryDto(groupId, "Cat Editada", "icon2", "desc2");
        var updateRes = await Http.PutAsync($"{Endpoint}/{created!.Id}", JsonBody(updateBody));

        Assert.Equal(HttpStatusCode.NoContent, updateRes.StatusCode);

        var getRes = await Http.GetAsync($"{Endpoint}/{created.Id}");
        var fetched = await ReadJsonAsync<CategoryDto>(getRes);
        Assert.Equal("Cat Editada", fetched!.Name);
    }

    [DockerFact]
    public async Task Delete_WhenValid_DeletesCategoryAndReturnsNoContent()
    {
        var groupId = await CreateGroupAsync();
        var createBody = new CreateCategoryDto(groupId, "Cat Para Borrar", "icon", "desc");
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
        var groupId = await CreateGroupAsync();
        var cat1Res = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto(groupId, "Cat Reorder 1", "icon1", "desc", 0)));
        var cat1 = await ReadJsonAsync<CategoryDto>(cat1Res);
        var cat2Res = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto(groupId, "Cat Reorder 2", "icon2", "desc", 1)));
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

        var groupId = await CreateGroupAsync();
        var catRes = await Http.PostAsync(Endpoint, JsonBody(new CreateCategoryDto(groupId, "Cat Con Estructuras", "icon", "desc")));
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
}
