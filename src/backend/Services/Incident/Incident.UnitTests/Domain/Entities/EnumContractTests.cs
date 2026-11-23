using Incident.Domain.Entities;

namespace Incident.UnitTests.Domain.Entities;

/// <summary>
/// Fija el contrato numérico de los enums: los endpoints reciben/devuelven
/// los valores de estado como enteros, así que un cambio aquí es un cambio de API.
/// </summary>
public class EnumContractTests
{
    [Theory]
    [InlineData(Objectenum.Pending, 0)]
    [InlineData(Objectenum.In_Process, 1)]
    [InlineData(Objectenum.Resolved, 2)]
    [InlineData(Objectenum.Canceled, 3)]
    public void Objectenum_MantieneSusValores(Objectenum valor, int esperado) =>
        Assert.Equal(esperado, (int)valor);

    [Theory]
    [InlineData(Tickets.Pending, 0)]
    [InlineData(Tickets.In_Process, 1)]
    [InlineData(Tickets.Resolved, 2)]
    [InlineData(Tickets.Dismissed, 3)]
    public void Tickets_MantieneSusValores(Tickets valor, int esperado) =>
        Assert.Equal(esperado, (int)valor);

    [Theory]
    [InlineData(Complainenum.Claim, 0)]
    [InlineData(Complainenum.Found, 1)]
    [InlineData(Complainenum.Match, 2)]
    [InlineData(Complainenum.Pickup, 3)]
    public void Complainenum_MantieneSusValores(Complainenum valor, int esperado) =>
        Assert.Equal(esperado, (int)valor);

    [Fact]
    public void GeoPoint_PorDefectoEsUnPuntoConDosCoordenadas()
    {
        var punto = new GeoPoint();

        Assert.Equal("Point", punto.Type);
        Assert.Equal(2, punto.Coordinates.Length);
    }

    [Fact]
    public void GeoPoint_ConstructorRecibeLongitudYLATitudEnEseOrden()
    {
        var punto = new GeoPoint(longitude: -71.2345, latitude: -33.0456);

        Assert.Equal(-71.2345, punto.Coordinates[0]);
        Assert.Equal(-33.0456, punto.Coordinates[1]);
    }
}
