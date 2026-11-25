using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Campus.Application.DTOs;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

[Collection(PostgreSqlCollection.Name)]
public class SecurityEndpointsTests : ApiTestBase
{
    public SecurityEndpointsTests(PostgreSqlFixture fixture) : base(fixture) { }

    public static TheoryData<string, string, object?> AllProtectedWriteEndpoints()
    {
        var sampleId = Guid.NewGuid();
        return new TheoryData<string, string, object?>
        {
            // Campuses
            { "POST", "/api/campus/campuses", new CreateCampusDto("Campus Sec", "Calle 123", -38.7, -72.6) },
            { "PUT", $"/api/campus/campuses/{sampleId}", new UpdateCampusDto("Campus Sec", "Calle 456", -38.7, -72.6) },
            { "PATCH", $"/api/campus/campuses/{sampleId}/location", new UpdateLocationDto(-38.71, -72.61) },
            { "DELETE", $"/api/campus/campuses/{sampleId}", null },

            // Buildings
            { "POST", "/api/campus/buildings", new CreateBuildingDto(sampleId, "Edificio Sec", 2, -38.7, -72.6) },
            { "PUT", $"/api/campus/buildings/{sampleId}", new UpdateBuildingDto(sampleId, "Edificio Sec", 3, -38.7, -72.6) },
            { "PATCH", $"/api/campus/buildings/{sampleId}/location", new UpdateLocationDto(-38.72, -72.62) },
            { "DELETE", $"/api/campus/buildings/{sampleId}", null },

            // Categories
            { "POST", "/api/campus/categories", new CreateCategoryDto("Cat Sec", "icon", "Desc") },
            { "PUT", $"/api/campus/categories/{sampleId}", new UpdateCategoryDto("Cat Sec", "icon", "Desc") },
            { "PUT", "/api/campus/categories/reorder", new List<ReorderItemDto> { new(sampleId, 1) } },
            { "DELETE", $"/api/campus/categories/{sampleId}", null },

            // Rooms
            { "POST", "/api/campus/rooms", new CreateRoomDto(sampleId, "Sala 101", 1) },
            { "PUT", $"/api/campus/rooms/{sampleId}", new UpdateRoomDto(sampleId, "Sala 102", 2) },
            { "DELETE", $"/api/campus/rooms/{sampleId}", null },

            // Structures
            { "POST", "/api/campus/structures", new CreateStructureDto(sampleId, null, "Estructura Sec", -38.7, -72.6) },
            { "PUT", $"/api/campus/structures/{sampleId}", new UpdateStructureDto(sampleId, null, "Estructura Sec", -38.7, -72.6) },
            { "PATCH", $"/api/campus/structures/{sampleId}/location", new UpdateLocationDto(-38.73, -72.63) },
            { "DELETE", $"/api/campus/structures/{sampleId}", null }
        };
    }

    public static TheoryData<string> NonAdminRoles() => new()
    {
        "Student",
        "Teacher",
        "ComplaintsOfficer",
        "ObjectsOfficer",
        "Official",
        "admin"
    };

    private static HttpRequestMessage BuildRequest(string method, string url, object? payload)
    {
        var request = new HttpRequestMessage(new HttpMethod(method), url);
        if (payload is not null)
            request.Content = JsonBody(payload);

        return request;
    }

    [DockerTheory]
    [MemberData(nameof(AllProtectedWriteEndpoints))]
    public async Task AllWriteEndpoints_WhenUnauthenticated_Return401Unauthorized(string method, string url, object? payload)
    {
        using var client = CreateUnauthenticatedClient();
        using var request = BuildRequest(method, url, payload);

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerTheory]
    [MemberData(nameof(AllProtectedWriteEndpoints))]
    public async Task AllWriteEndpoints_WhenAuthenticatedWithStudentRole_Return403Forbidden(string method, string url, object? payload)
    {
        using var client = CreateClientWithRole("Student");
        using var request = BuildRequest(method, url, payload);

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [DockerTheory]
    [MemberData(nameof(NonAdminRoles))]
    public async Task WriteEndpointsAcrossControllers_WhenUserHasNonAdminRole_Return403Forbidden(string nonAdminRole)
    {
        using var client = CreateClientWithRole(nonAdminRole);
        var id = Guid.NewGuid();

        var responses = await Task.WhenAll(
            client.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Campus", "Dir", -38.7, -72.6))),
            client.PutAsync($"/api/campus/buildings/{id}", JsonBody(new UpdateBuildingDto(id, "Edificio", 2, -38.7, -72.6))),
            client.PutAsync("/api/campus/categories/reorder", JsonBody(new List<ReorderItemDto> { new(id, 0) })),
            client.PutAsync($"/api/campus/rooms/{id}", JsonBody(new UpdateRoomDto(id, "Sala 1", 1))),
            client.PatchAsync($"/api/campus/structures/{id}/location", JsonBody(new UpdateLocationDto(-38.7, -72.6)))
        );

        Assert.All(responses, res => Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode));
    }

    [DockerFact]
    public async Task WriteEndpoints_WhenTokenHasNoRoleClaim_Return403Forbidden()
    {
        var tokenWithoutRole = TestJwtGenerator.GenerateCustomToken(role: null);
        using var client = CreateClientWithToken(tokenWithoutRole);
        var id = Guid.NewGuid();

        var postCampus = await client.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Sin Rol", "Dir", -38.7, -72.6)));
        var deleteCategory = await client.DeleteAsync($"/api/campus/categories/{id}");

        Assert.Equal(HttpStatusCode.Forbidden, postCampus.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, deleteCategory.StatusCode);
    }

    [DockerFact]
    public async Task WriteEndpoints_WhenTokenIsExpired_Return401Unauthorized()
    {
        var expiredAdminToken = TestJwtGenerator.GenerateExpiredToken("Admin");
        using var client = CreateClientWithToken(expiredAdminToken);

        var response = await client.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Expirado", "Dir", -38.7, -72.6)));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task WriteEndpoints_WhenTokenHasInvalidSignature_Return401Unauthorized()
    {
        var forgedAdminToken = TestJwtGenerator.GenerateTokenWithInvalidKey("Admin");
        using var client = CreateClientWithToken(forgedAdminToken);

        var response = await client.PostAsync("/api/campus/categories", JsonBody(new CreateCategoryDto("Forjada", "icon", "desc")));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [DockerFact]
    public async Task WriteEndpoints_WhenTokenHasInvalidIssuerOrAudience_Return401Unauthorized()
    {
        using var badIssuerClient = CreateClientWithToken(TestJwtGenerator.GenerateTokenWithInvalidIssuer("Admin"));
        using var badAudienceClient = CreateClientWithToken(TestJwtGenerator.GenerateTokenWithInvalidAudience("Admin"));

        var issuerResponse = await badIssuerClient.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("BadIssuer", "Dir", 0, 0)));
        var audienceResponse = await badAudienceClient.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("BadAudience", "Dir", 0, 0)));

        Assert.Equal(HttpStatusCode.Unauthorized, issuerResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, audienceResponse.StatusCode);
    }

    [DockerFact]
    public async Task WriteEndpoints_WhenTokenIsMalformedOrWrongScheme_Return401Unauthorized()
    {
        using var malformedClient = CreateClientWithToken("not.a.valid.jwt");
        using var wrongSchemeClient = Factory.CreateClient();
        wrongSchemeClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", TestJwtGenerator.GenerateToken("Admin"));

        var malformedResponse = await malformedClient.DeleteAsync($"/api/campus/rooms/{Guid.NewGuid()}");
        var wrongSchemeResponse = await wrongSchemeClient.DeleteAsync($"/api/campus/rooms/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Unauthorized, malformedResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, wrongSchemeResponse.StatusCode);
    }

    [DockerFact]
    public async Task RejectedMutations_401And403_PreserveDatabaseStateIntegrity()
    {
        var campusRes = await Http.PostAsync("/api/campus/campuses", JsonBody(new CreateCampusDto("Campus Integro", "Av. Original 100", -38.73, -72.59)));
        var campus = await ReadJsonAsync<CampusDto>(campusRes);

        var categoryRes = await Http.PostAsync("/api/campus/categories", JsonBody(new CreateCategoryDto("Cat Integra", "shield", "Original", 3)));
        var category = await ReadJsonAsync<CategoryDto>(categoryRes);

        using var anonClient = CreateUnauthenticatedClient();
        using var teacherClient = CreateClientWithRole("Teacher");

        Assert.Equal(
            HttpStatusCode.Unauthorized,
            (await anonClient.PutAsync($"/api/campus/campuses/{campus!.Id}", JsonBody(new UpdateCampusDto("Hackeado", "Calle Falsa", 0, 0)))).StatusCode);

        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await teacherClient.DeleteAsync($"/api/campus/campuses/{campus.Id}")).StatusCode);

        Assert.Equal(
            HttpStatusCode.Forbidden,
            (await teacherClient.PutAsync("/api/campus/categories/reorder", JsonBody(new List<ReorderItemDto> { new(category!.Id, 99) }))).StatusCode);

        var fetchedCampus = await ReadJsonAsync<CampusDto>(await Http.GetAsync($"/api/campus/campuses/{campus.Id}"));
        var fetchedCategory = await ReadJsonAsync<CategoryDto>(await Http.GetAsync($"/api/campus/categories/{category.Id}"));

        Assert.NotNull(fetchedCampus);
        Assert.Equal("Campus Integro", fetchedCampus.Name);
        Assert.Equal("Av. Original 100", fetchedCampus.Address);

        Assert.NotNull(fetchedCategory);
        Assert.Equal("Cat Integra", fetchedCategory.Name);
        Assert.Equal(3, fetchedCategory.Order);
    }

    [DockerTheory]
    [InlineData("/api/campus/campuses")]
    [InlineData("/api/campus/buildings")]
    [InlineData("/api/campus/buildings/locations")]
    [InlineData("/api/campus/categories")]
    [InlineData("/api/campus/rooms")]
    [InlineData("/api/campus/rooms/search?term=CJP")]
    [InlineData("/api/campus/structures")]
    [InlineData("/api/campus/structures/locations")]
    public async Task ReadEndpoints_WhenCalledByNonAdminOrUnauthenticated_Return200Ok(string endpoint)
    {
        using var studentClient = CreateClientWithRole("Student");
        using var anonClient = CreateUnauthenticatedClient();

        var studentRes = await studentClient.GetAsync(endpoint);
        var anonRes = await anonClient.GetAsync(endpoint);

        Assert.Equal(HttpStatusCode.OK, studentRes.StatusCode);
        Assert.Equal(HttpStatusCode.OK, anonRes.StatusCode);
    }

    [DockerFact]
    public async Task Post_WhenUserIsAdmin_SucceedsWith201()
    {
        using var client = CreateClientWithRole("Admin");
        var body = new CreateCampusDto("Campus Admin Auth", "Avda Alemania 0123", -38.73, -72.59);

        var response = await client.PostAsync("/api/campus/campuses", JsonBody(body));

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
