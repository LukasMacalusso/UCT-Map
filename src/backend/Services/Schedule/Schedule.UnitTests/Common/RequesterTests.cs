using Schedule.Application.Common;

namespace Schedule.UnitTests.Common;

public class RequesterTests
{
    [Fact]
    public void CanAccess_WhenRequesterIsTheOwner_ReturnsTrue()
    {
        var userId = Guid.NewGuid();

        Assert.True(new Requester(userId, IsAdmin: false).CanAccess(userId));
    }

    [Fact]
    public void CanAccess_WhenRequesterIsAnotherUser_ReturnsFalse()
    {
        Assert.False(new Requester(Guid.NewGuid(), IsAdmin: false).CanAccess(Guid.NewGuid()));
    }

    [Fact]
    public void CanAccess_WhenRequesterIsAdmin_ReturnsTrueForAnyOwner()
    {
        Assert.True(new Requester(Guid.NewGuid(), IsAdmin: true).CanAccess(Guid.NewGuid()));
    }
}
