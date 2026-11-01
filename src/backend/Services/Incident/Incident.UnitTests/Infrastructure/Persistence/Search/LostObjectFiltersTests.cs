using System.Text.RegularExpressions;
using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.Infrastructure.Persistence.Search;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Driver;

namespace Incident.UnitTests.Infrastructure.Persistence.Search;

/// <summary>
/// Verifica la traducción de los criterios de búsqueda de objetos perdidos a
/// filtros y ordenamientos de MongoDB, sin necesidad de un servidor real.
/// </summary>
public class LostObjectFiltersTests
{
    private static LostObjectSearchCriteria Criteria(
        string? title = null,
        Guid? structureId = null,
        Objectenum? status = null,
        LostObjectSortField sortBy = LostObjectSortField.ReportedAt,
        bool descending = false,
        int page = 1,
        int pageSize = 10) =>
        new(title, structureId, status, sortBy, descending, page, pageSize);

    private static BsonDocument Render(FilterDefinition<LostObject> filter) =>
        filter.Render(new RenderArgs<LostObject>(
            BsonSerializer.LookupSerializer<LostObject>(),
            BsonSerializer.SerializerRegistry));

    private static BsonDocument Render(SortDefinition<LostObject> sort) =>
        sort.Render(new RenderArgs<LostObject>(
            BsonSerializer.LookupSerializer<LostObject>(),
            BsonSerializer.SerializerRegistry));

    [Fact]
    public void Build_SinCriterios_DevuelveUnFiltroVacio()
    {
        var filter = LostObjectFilters.Build(Criteria());

        Assert.Empty(Render(filter));
    }

    [Fact]
    public void Build_ConTitulo_FiltraPorTituloCaseInsensitive()
    {
        var filter = LostObjectFilters.Build(Criteria(title: "Mochila"));

        var rendered = Render(filter);

        var regex = rendered["title"].AsBsonRegularExpression;
        Assert.Equal("Mochila", regex.Pattern);
        Assert.Contains("i", regex.Options);
    }

    [Fact]
    public void Build_ConStructureId_FiltraPorStructure()
    {
        var structureId = Guid.NewGuid();

        var filter = LostObjectFilters.Build(Criteria(structureId: structureId));

        Assert.True(Render(filter).Contains("structure_id"));
    }

    [Fact]
    public void Build_ConStatus_FiltraPorStatus()
    {
        var filter = LostObjectFilters.Build(Criteria(status: Objectenum.Resolved));

        Assert.True(Render(filter).Contains("status"));
    }

    [Fact]
    public void Build_ConTodosLosCriterios_CombinaLosFiltros()
    {
        var filter = LostObjectFilters.Build(Criteria(
            title: "Mochila",
            structureId: Guid.NewGuid(),
            status: Objectenum.In_Process));

        var rendered = Render(filter);

        Assert.True(rendered.Contains("title"));
        Assert.True(rendered.Contains("structure_id"));
        Assert.True(rendered.Contains("status"));
    }

    [Fact]
    public void ByTitle_EscapaLosCaracteresRegex()
    {
        var filter = LostObjectFilters.ByTitle("Mochila (negra)");

        var regex = Render(filter)["title"].AsBsonRegularExpression;

        Assert.Equal(Regex.Escape("Mochila (negra)"), regex.Pattern);
    }

    [Fact]
    public void ByStructure_UsaElGuidComoFiltro()
    {
        var structureId = Guid.NewGuid();

        var filter = LostObjectFilters.ByStructure(structureId);

        Assert.True(Render(filter).Contains("structure_id"));
    }

    [Fact]
    public void ByStatus_UsaElStatusComoFiltro()
    {
        var filter = LostObjectFilters.ByStatus(Objectenum.Canceled);

        Assert.True(Render(filter).Contains("status"));
    }

    [Theory]
    [InlineData(LostObjectSortField.ReportedAt, false, "date_lost_object", 1)]
    [InlineData(LostObjectSortField.ReportedAt, true, "date_lost_object", -1)]
    [InlineData(LostObjectSortField.Title, false, "title", 1)]
    [InlineData(LostObjectSortField.Title, true, "title", -1)]
    [InlineData(LostObjectSortField.Status, false, "status", 1)]
    [InlineData(LostObjectSortField.Status, true, "status", -1)]
    public void Sort_UsaElCampoYLaDireccionIndicados(
        LostObjectSortField field,
        bool descending,
        string expectedField,
        int expectedDirection)
    {
        var sort = LostObjectFilters.Sort(field, descending);

        var rendered = Render(sort);

        Assert.Equal(expectedDirection, rendered[expectedField].ToInt32());
    }
}
