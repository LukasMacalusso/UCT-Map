using System;
using System.Linq;
using System.Reflection;
using Campus.API.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;
using Xunit;

namespace Campus.UnitTests.API.Controllers;

public class ControllerAuthorizationTests
{
    [Theory]
    [InlineData(typeof(BuildingController), "Create")]
    [InlineData(typeof(BuildingController), "Update")]
    [InlineData(typeof(BuildingController), "UpdateLocation")]
    [InlineData(typeof(BuildingController), "Delete")]
    [InlineData(typeof(CampusController), "Create")]
    [InlineData(typeof(CampusController), "Update")]
    [InlineData(typeof(CampusController), "UpdateLocation")]
    [InlineData(typeof(CampusController), "Delete")]
    [InlineData(typeof(CategoryController), "Create")]
    [InlineData(typeof(CategoryController), "Update")]
    [InlineData(typeof(CategoryController), "Reorder")]
    [InlineData(typeof(CategoryController), "Delete")]
    [InlineData(typeof(RoomController), "Create")]
    [InlineData(typeof(RoomController), "Update")]
    [InlineData(typeof(RoomController), "Delete")]
    [InlineData(typeof(StructureController), "Create")]
    [InlineData(typeof(StructureController), "Update")]
    [InlineData(typeof(StructureController), "UpdateLocation")]
    [InlineData(typeof(StructureController), "Delete")]
    public void WriteEndpoints_ShouldHaveAuthorizeAttribute_WithAdminRole(Type controllerType, string actionName)
    {
        var method = controllerType.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly)
            .FirstOrDefault(m => m.Name == actionName);

        Assert.NotNull(method);
        Assert.Null(method.GetCustomAttribute<AllowAnonymousAttribute>());

        var authorizeAttr = method.GetCustomAttribute<AuthorizeAttribute>()
            ?? controllerType.GetCustomAttribute<AuthorizeAttribute>();
        Assert.NotNull(authorizeAttr);
        Assert.Equal("Admin", authorizeAttr.Roles);
    }

    [Theory]
    [InlineData(typeof(BuildingController), "GetAll")]
    [InlineData(typeof(BuildingController), "GetLocations")]
    [InlineData(typeof(BuildingController), "GetById")]
    [InlineData(typeof(CampusController), "GetAll")]
    [InlineData(typeof(CampusController), "GetById")]
    [InlineData(typeof(CampusController), "GetMap")]
    [InlineData(typeof(CategoryController), "GetAll")]
    [InlineData(typeof(CategoryController), "GetById")]
    [InlineData(typeof(RoomController), "GetAll")]
    [InlineData(typeof(RoomController), "Search")]
    [InlineData(typeof(RoomController), "GetByBuilding")]
    [InlineData(typeof(RoomController), "GetById")]
    [InlineData(typeof(StructureController), "GetAll")]
    [InlineData(typeof(StructureController), "GetLocations")]
    [InlineData(typeof(StructureController), "GetById")]
    public void ReadEndpoints_ShouldNotRequireAdminRole(Type controllerType, string actionName)
    {
        var method = controllerType.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly)
            .Where(m => m.GetCustomAttribute<NonActionAttribute>() == null)
            .FirstOrDefault(m => m.Name == actionName);

        Assert.NotNull(method);

        var authorizeAttr = method.GetCustomAttribute<AuthorizeAttribute>();
        Assert.True(authorizeAttr == null || authorizeAttr.Roles != "Admin");
    }

    [Fact]
    public void AllMutatingHttpActionsInAssembly_MustEnforceAdminRoleAndNeverAllowAnonymous()
    {
        var controllerTypes = typeof(CampusController).Assembly
            .GetTypes()
            .Where(t => !t.IsAbstract && typeof(ControllerBase).IsAssignableFrom(t))
            .ToList();

        Assert.Equal(5, controllerTypes.Count);

        var mutatingActions = controllerTypes
            .SelectMany(t => t.GetMethods(BindingFlags.Instance | BindingFlags.Public | BindingFlags.DeclaredOnly)
                .Where(m => m.GetCustomAttribute<NonActionAttribute>() == null)
                .Where(m => m.GetCustomAttribute<HttpPostAttribute>() != null
                    || m.GetCustomAttribute<HttpPutAttribute>() != null
                    || m.GetCustomAttribute<HttpPatchAttribute>() != null
                    || m.GetCustomAttribute<HttpDeleteAttribute>() != null)
                .Select(m => (Controller: t, Method: m)))
            .ToList();

        Assert.Equal(19, mutatingActions.Count);

        foreach (var (controller, method) in mutatingActions)
        {
            Assert.Null(method.GetCustomAttribute<AllowAnonymousAttribute>());

            var authorizeAttr = method.GetCustomAttribute<AuthorizeAttribute>()
                ?? controller.GetCustomAttribute<AuthorizeAttribute>();

            Assert.True(authorizeAttr != null, $"{controller.Name}.{method.Name} must have [Authorize].");
            Assert.Equal("Admin", authorizeAttr.Roles);
        }
    }
}
