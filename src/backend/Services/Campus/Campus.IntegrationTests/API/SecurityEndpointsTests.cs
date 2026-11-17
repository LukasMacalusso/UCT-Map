using System;
using System.Net;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class SecurityEndpointsTests : ApiTestBase
{
    public SecurityEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    [DockerFact]
    public async Task Post_WhenUnauthenticated_Returns401Unauthorized()
    {
        var client = CreateUnauthenticatedClient();
        var body = new CreateCampusDto("Campus Sin Auth", "Calle 123", -38.7, -72.6);

        var response = await client.PostAsync("/api/campus/campuses", JsonBody(body));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task Post_WhenUserIsNotAdmin_Returns403Forbidden()
    {
        var client = CreateClientWithRole("Student");
        var body = new CreateCampusDto("Campus Con Student", "Calle 123", -38.7, -72.6);

        var response = await client.PostAsync("/api/campus/campuses", JsonBody(body));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [DockerFact]
    public async Task Put_WhenUnauthenticated_Returns401Unauthorized()
    {
        var client = CreateUnauthenticatedClient();
        var body = new UpdateCampusDto("Campus Update", "Calle 456", -38.7, -72.6);

        var response = await client.PutAsync($"/api/campus/campuses/{Guid.NewGuid()}", JsonBody(body));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task Put_WhenUserIsNotAdmin_Returns403Forbidden()
    {
        var client = CreateClientWithRole("Teacher");
        var body = new UpdateCampusDto("Campus Update", "Calle 456", -38.7, -72.6);

        var response = await client.PutAsync($"/api/campus/campuses/{Guid.NewGuid()}", JsonBody(body));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [DockerFact]
    public async Task PatchLocation_WhenUnauthenticated_Returns401Unauthorized()
    {
        var client = CreateUnauthenticatedClient();
        var body = new UpdateLocationDto(-38.71, -72.61);

        var response = await client.PatchAsync($"/api/campus/campuses/{Guid.NewGuid()}/location", JsonBody(body));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task PatchLocation_WhenUserIsNotAdmin_Returns403Forbidden()
    {
        var client = CreateClientWithRole("Student");
        var body = new UpdateLocationDto(-38.71, -72.61);

        var response = await client.PatchAsync($"/api/campus/campuses/{Guid.NewGuid()}/location", JsonBody(body));

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [DockerFact]
    public async Task Delete_WhenUnauthenticated_Returns401Unauthorized()
    {
        var client = CreateUnauthenticatedClient();

        var response = await client.DeleteAsync($"/api/campus/campuses/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task Delete_WhenUserIsNotAdmin_Returns403Forbidden()
    {
        var client = CreateClientWithRole("Official");

        var response = await client.DeleteAsync($"/api/campus/campuses/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [DockerFact]
    public async Task Building_WriteEndpoints_RequireAdminRole()
    {
        var client = CreateClientWithRole("Student");
        var body = new CreateBuildingDto(Guid.NewGuid(), "Edificio Test", 2, -38.7, -72.6);

        var postResponse = await client.PostAsync("/api/campus/buildings", JsonBody(body));
        Assert.Equal(HttpStatusCode.Forbidden, postResponse.StatusCode);

        var deleteResponse = await client.DeleteAsync($"/api/campus/buildings/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);
    }

    [DockerFact]
    public async Task Category_WriteEndpoints_RequireAdminRole()
    {
        var client = CreateClientWithRole("Student");
        var body = new CreateCategoryDto("Categoria Test", "Icon", "Desc");

        var postResponse = await client.PostAsync("/api/campus/categories", JsonBody(body));
        Assert.Equal(HttpStatusCode.Forbidden, postResponse.StatusCode);

        var deleteResponse = await client.DeleteAsync($"/api/campus/categories/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);
    }

    [DockerFact]
    public async Task Room_WriteEndpoints_RequireAdminRole()
    {
        var client = CreateClientWithRole("Student");
        var body = new CreateRoomDto(Guid.NewGuid(), null, "Sala 101", 1);

        var postResponse = await client.PostAsync("/api/campus/rooms", JsonBody(body));
        Assert.Equal(HttpStatusCode.Forbidden, postResponse.StatusCode);

        var deleteResponse = await client.DeleteAsync($"/api/campus/rooms/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);
    }

    [DockerFact]
    public async Task Structure_WriteEndpoints_RequireAdminRole()
    {
        var client = CreateClientWithRole("Student");
        var body = new CreateStructureDto(Guid.NewGuid(), null, "Estructura Test", -38.7, -72.6);

        var postResponse = await client.PostAsync("/api/campus/structures", JsonBody(body));
        Assert.Equal(HttpStatusCode.Forbidden, postResponse.StatusCode);

        var deleteResponse = await client.DeleteAsync($"/api/campus/structures/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);
    }

    [DockerFact]
    public async Task Post_WhenUserIsAdmin_SucceedsWith201()
    {
        var client = CreateClientWithRole("Admin");
        var body = new CreateCampusDto("Campus Admin Auth", "Avda Alemania 0123", -38.73, -72.59);

        var response = await client.PostAsync("/api/campus/campuses", JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
