using System.Runtime.CompilerServices;
using Incident.Infrastructure.Persistence;

namespace Incident.UnitTests;

/// <summary>
/// Inicializa el mapeo de BSON una sola vez al cargar el assembly de pruebas,
/// igual que lo hace la API al arrancar. Los tests que renderizan filtros y
/// ordenamientos necesitan los nombres reales de los campos (user_id,
/// structure_id, date_ticket, etc.) definidos en los class maps.
/// </summary>
internal static class TestAssemblySetup
{
    [ModuleInitializer]
    internal static void Initialize() => MongoDbConfiguration.RegisterClassMaps();
}
