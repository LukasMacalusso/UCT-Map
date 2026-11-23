namespace Incident.IntegrationTests.Fixtures;

/// Genera nombres de base de datos únicos y válidos: MongoDB limita los
/// nombres a 63 caracteres, así que se recorta el identificador de la clase.

public static class TestDatabaseNames
{
    private const int MaxSeedLength = 20;

    public static string New(string seed)
    {
        var safeSeed = new string(seed
            .ToLowerInvariant()
            .Where(c => char.IsAsciiLetterOrDigit(c) || c == '_')
            .ToArray());

        if (safeSeed.Length > MaxSeedLength)
            safeSeed = safeSeed[..MaxSeedLength];

        return $"inct_{safeSeed}_{Guid.NewGuid():N}";
    }
}
