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
}
