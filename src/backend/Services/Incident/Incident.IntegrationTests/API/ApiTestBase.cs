using Incident.IntegrationTests.Fixtures;
using System.Net.Http.Json;
using System.Text.Json;

namespace Incident.IntegrationTests.API;

/// <summary>
/// Base de los tests end-to-end: levanta la API real (Program.cs completo)
/// con un HttpClient, y la cierra limpio al terminar cada clase de test.
/// </summary>
public abstract class ApiTestBase : IAsyncLifetime
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    private readonly MongoFixture _fixture;

    protected IncidentApiFactory Factory { get; private set; } = null!;
    protected HttpClient Http { get; private set; } = null!;

    protected ApiTestBase(MongoFixture fixture) => _fixture = fixture;

    public Task InitializeAsync()
    {
        Factory = new IncidentApiFactory(_fixture);
        Http = Factory.CreateClient();
        ConfigureHttp(Http);
        return Task.CompletedTask;
    }

    /// <summary>
    /// Permite a las clases derivadas ajustar el <see cref="HttpClient"/> (por
    /// ejemplo agregar el header Authorization) antes de correr los tests.
    /// </summary>
    protected virtual void ConfigureHttp(HttpClient http) { }

    public async Task DisposeAsync()
    {
        Http.Dispose();
        await Factory.DisposeAsync();
    }

    protected static Task<T?> ReadJsonAsync<T>(HttpResponseMessage response) =>
        response.Content.ReadFromJsonAsync<T>(Json);

    protected static JsonContent JsonBody(object body) => JsonContent.Create(body);
}
