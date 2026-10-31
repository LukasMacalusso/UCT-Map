using Xunit;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Igual a [Theory] pero se omite cuando no hay Docker disponible, para los
/// tests parametrizados que dependen de Testcontainers.
/// </summary>
public sealed class DockerTheoryAttribute : TheoryAttribute
{
    public DockerTheoryAttribute()
    {
        if (!DockerCheck.IsAvailable.Value)
            Skip = "Docker no está disponible: este test necesita un daemon de Docker para levantar MongoDB (Testcontainers).";
    }
}
