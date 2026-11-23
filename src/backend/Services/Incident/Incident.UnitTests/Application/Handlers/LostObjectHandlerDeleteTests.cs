using ErrorOr;
using Incident.Application.Handlers;
using Incident.Domain.Entities;
using Incident.Domain.Interfaces;
using NSubstitute;

namespace Incident.UnitTests.Application.Handlers;

/// <summary>
/// Reglas de autorización del DELETE de objetos perdidos: Admin, ObjectsOfficer,
/// ComplaintsOfficer o el dueño del objeto.
/// </summary>
public class LostObjectHandlerDeleteTests
{
    private const string ObjectId = "64b000000000000000000001";

    private readonly ILostObjectRepository _repository = Substitute.For<ILostObjectRepository>();
    private readonly LostObjectHandler _handler;

    public LostObjectHandlerDeleteTests()
    {
        _handler = new LostObjectHandler(_repository);
    }

    private static LostObject NewLostObject(string id = ObjectId) => new()
    {
        Id = id,
        Title = "Mochila negra",
        Description = "Dejada en la biblioteca",
        Status = Objectenum.Pending,
        ReportedAt = new DateTime(2026, 10, 5, 10, 30, 0, DateTimeKind.Utc),
        PhotoUrl = "https://campus.uct.cl/mochila.png",
        StructureRefId = Guid.NewGuid(),
        UserRefId = Guid.NewGuid()
    };

    [Fact]
    public async Task DeleteAsync_CuandoElObjetoNoExiste_RetornaNotFoundYNoBorra()
    {
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(null));

        var result = await _handler.DeleteAsync(ObjectId, "Admin", Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.NotFound, result.FirstError.Type);
        Assert.Equal("LostObject.NotFound", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().DeleteAsync(default!);
    }

    [Theory]
    [InlineData("Admin")]
    [InlineData("ObjectsOfficer")]
    [InlineData("ComplaintsOfficer")]
    public async Task DeleteAsync_ConRolAutorizado_Borra(string role)
    {
        var lostObject = NewLostObject();
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(lostObject));
        _repository.DeleteAsync(ObjectId).Returns(Task.FromResult(true));

        var result = await _handler.DeleteAsync(ObjectId, role, Guid.NewGuid().ToString());

        Assert.False(result.IsError);
        Assert.Equal(Result.Success, result.Value);
        await _repository.Received(1).DeleteAsync(ObjectId);
    }

    [Theory]
    [InlineData("Student")]
    [InlineData("")]
    [InlineData("admin")]
    public async Task DeleteAsync_ConRolNoAutorizado_RetornaForbiddenYNoBorra(string role)
    {
        var lostObject = NewLostObject();
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(lostObject));

        var result = await _handler.DeleteAsync(ObjectId, role, Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
        Assert.Equal("LostObject.Forbidden", result.FirstError.Code);
        await _repository.DidNotReceiveWithAnyArgs().DeleteAsync(default!);
    }

    [Fact]
    public async Task DeleteAsync_CuandoEsElDueno_BorraAunqueNoTengaRol()
    {
        var lostObject = NewLostObject();
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(lostObject));
        _repository.DeleteAsync(ObjectId).Returns(Task.FromResult(true));

        var result = await _handler.DeleteAsync(ObjectId, null!, lostObject.UserRefId.ToString());

        Assert.False(result.IsError);
        await _repository.Received(1).DeleteAsync(ObjectId);
    }

    [Fact]
    public async Task DeleteAsync_ConRolNulo_RetornaForbidden()
    {
        var lostObject = NewLostObject();
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(lostObject));

        var result = await _handler.DeleteAsync(ObjectId, null!, Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Forbidden, result.FirstError.Type);
    }

    [Fact]
    public async Task DeleteAsync_CuandoElRepositorioNoBorra_RetornaFailure()
    {
        var lostObject = NewLostObject();
        _repository.GetByIdAsync(ObjectId).Returns(Task.FromResult<LostObject?>(lostObject));
        _repository.DeleteAsync(ObjectId).Returns(Task.FromResult(false));

        var result = await _handler.DeleteAsync(ObjectId, "Admin", Guid.NewGuid().ToString());

        Assert.True(result.IsError);
        Assert.Equal(ErrorType.Failure, result.FirstError.Type);
        Assert.Equal("LostObject.UpdateFailed", result.FirstError.Code);
    }
}
