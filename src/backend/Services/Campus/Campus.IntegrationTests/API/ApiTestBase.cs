using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Campus.IntegrationTests.Fixtures;
using Xunit;

namespace Campus.IntegrationTests.API;

/// <summary>
/// Base de los tests end-to-end de API de Campus.
/// </summary>
public abstract class ApiTestBase : IAsyncLifetime
{
    protected static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private readonly PostgreSqlFixture _fixture;

    protected CampusApiFactory Factory { get; private set; } = null!;
    protected HttpClient Http { get; private set; } = null!;

    protected ApiTestBase(PostgreSqlFixture fixture) => _fixture = fixture;

    public Task InitializeAsync()
    {
        if (_fixture.IsAvailable)
        {
            Factory = new CampusApiFactory(_fixture);
            Http = Factory.CreateClient();
        }
        return Task.CompletedTask;
    }

    public async Task DisposeAsync()
    {
        Http?.Dispose();
        if (Factory is not null)
            await Factory.DisposeAsync();
    }

    protected static Task<T?> ReadJsonAsync<T>(HttpResponseMessage response) =>
        response.Content.ReadFromJsonAsync<T>(Json);

    protected static JsonContent JsonBody(object body) => JsonContent.Create(body);
}
