using System.Diagnostics;

namespace Incident.IntegrationTests.Fixtures;

/// <summary>
/// Detecta una sola vez si hay un daemon de Docker accesible. Si no hay,
/// los tests marcados con <see cref="DockerFactAttribute"/> se omiten en
/// vez de fallar, para no romper <c>dotnet test</c> en máquinas sin Docker.
/// </summary>
public static class DockerCheck
{
    public static readonly Lazy<bool> IsAvailable = new(() =>
    {
        try
        {
            using var process = Process.Start(new ProcessStartInfo
            {
                FileName = "docker",
                Arguments = "info --format '{{.ServerVersion}}'",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            });

            if (process is null) return false;
            if (!process.WaitForExit(15_000)) { process.Kill(entireProcessTree: true); return false; }
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    });
}

/// <summary>
/// Igual a [Fact] pero se omite cuando no hay Docker disponible.
/// Se usa para todos los tests que dependen de Testcontainers.
/// </summary>
public sealed class DockerFactAttribute : FactAttribute
{
    public DockerFactAttribute()
    {
        if (!DockerCheck.IsAvailable.Value)
            Skip = "Docker no está disponible: este test necesita un daemon de Docker para levantar MongoDB (Testcontainers).";
    }
}
