using System.Text.RegularExpressions;
using Incident.Domain.Entities;
using Incident.Domain.Queries;
using Incident.Infrastructure.Persistence.Search;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Driver;

namespace Incident.UnitTests.Infrastructure.Persistence.Search;

/// <summary>
/// Verifica la traducción de los criterios de búsqueda de tickets a filtros y
/// ordenamientos de MongoDB, sin necesidad de un servidor real.
/// </summary>
public class TicketFiltersTests
{
    private static TicketSearchCriteria Criteria(
        Guid? userId = null,
        Guid? structureId = null,
        Tickets? type = null,
        bool? isActive = null,
        TicketSortBy sortBy = TicketSortBy.ReportedAt,
        GeoPoint? location = null,
        string? lostObjectId = null,
        ComplaintSearchCriteria? complaint = null,
        bool descending = false,
        int page = 1,
        int pageSize = 10) =>
        new(userId, structureId, type, isActive, sortBy, location, lostObjectId,
            complaint, descending, page, pageSize);

    private static BsonDocument Render(FilterDefinition<Ticket> filter) =>
        filter.Render(new RenderArgs<Ticket>(
            BsonSerializer.LookupSerializer<Ticket>(),
            BsonSerializer.SerializerRegistry));

    private static BsonDocument Render(SortDefinition<Ticket> sort) =>
        sort.Render(new RenderArgs<Ticket>(
            BsonSerializer.LookupSerializer<Ticket>(),
            BsonSerializer.SerializerRegistry));

    [Fact]
    public void Build_SinCriterios_DevuelveUnFiltroVacio()
    {
        var filter = TicketFilters.Build(Criteria());

        Assert.Empty(Render(filter));
    }

    [Fact]
    public void Build_ConTodosLosCriterios_CombinaLosFiltros()
    {
        var filter = TicketFilters.Build(Criteria(
            userId: Guid.NewGuid(),
            structureId: Guid.NewGuid(),
            type: Tickets.Resolved,
            isActive: true,
            location: new GeoPoint(-71.2345, -33.0456),
            lostObjectId: "64b000000000000000000001",
            complaint: new ComplaintSearchCriteria("Fuga", "Baño", Complainenum.Match)));

        var rendered = Render(filter);

        Assert.True(rendered.Contains("user_id"));
        Assert.True(rendered.Contains("structure_id"));
        Assert.True(rendered.Contains("ticket_type"));
        Assert.True(rendered.Contains("is_active"));
        Assert.True(rendered.Contains("location.coordinates"));
        Assert.True(rendered.Contains("object_id"));
        Assert.True(rendered.Contains("complaint_details.title"));
        Assert.True(rendered.Contains("complaint_details.description"));
        Assert.True(rendered.Contains("complaint_details.status"));
    }

    [Fact]
    public void Build_SoloConTituloDelReclamo_FiltraPorTitulo()
    {
        var filter = TicketFilters.Build(Criteria(
            complaint: new ComplaintSearchCriteria("Fuga", null, null)));

        Assert.True(Render(filter).Contains("complaint_details.title"));
    }

    [Fact]
    public void Build_SoloConDescripcionDelReclamo_FiltraPorDescripcion()
    {
        var filter = TicketFilters.Build(Criteria(
            complaint: new ComplaintSearchCriteria(null, "Baño", null)));

        Assert.True(Render(filter).Contains("complaint_details.description"));
    }

    [Fact]
    public void Build_SoloConStatusDelReclamo_FiltraPorStatus()
    {
        var filter = TicketFilters.Build(Criteria(
            complaint: new ComplaintSearchCriteria(null, null, Complainenum.Pickup)));

        Assert.True(Render(filter).Contains("complaint_details.status"));
    }

    [Fact]
    public void ByComplaintTitle_EscapaLosCaracteresRegex()
    {
        var filter = TicketFilters.ByComplaintTitle("Fuga (agua)");

        var rendered = Render(filter);
        var regex = rendered["complaint_details.title"].AsBsonRegularExpression;

        Assert.Equal(Regex.Escape("Fuga (agua)"), regex.Pattern);
        Assert.Contains("i", regex.Options);
    }

    [Fact]
    public void ByComplaintDescription_EscapaLosCaracteresRegex()
    {
        var filter = TicketFilters.ByComplaintDescription("Baño (2do piso)");

        var rendered = Render(filter);
        var regex = rendered["complaint_details.description"].AsBsonRegularExpression;

        Assert.Equal(Regex.Escape("Baño (2do piso)"), regex.Pattern);
    }

    [Fact]
    public void ByLocation_UsaLasCoordenadasDelPunto()
    {
        var location = new GeoPoint(-71.2345, -33.0456);

        var filter = TicketFilters.ByLocation(location);

        Assert.True(Render(filter).Contains("location.coordinates"));
    }

    [Theory]
    [InlineData(TicketSortBy.ReportedAt, false, "date_ticket", 1)]
    [InlineData(TicketSortBy.ReportedAt, true, "date_ticket", -1)]
    [InlineData(TicketSortBy.Status, false, "ticket_type", 1)]
    [InlineData(TicketSortBy.Status, true, "ticket_type", -1)]
    public void Sort_UsaElCampoYLaDireccionIndicados(
        TicketSortBy field,
        bool descending,
        string expectedField,
        int expectedDirection)
    {
        var sort = TicketFilters.Sort(field, descending);

        var rendered = Render(sort);

        Assert.Equal(expectedDirection, rendered[expectedField].ToInt32());
    }
}
