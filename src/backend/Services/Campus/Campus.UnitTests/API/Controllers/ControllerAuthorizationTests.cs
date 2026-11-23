using System;
using System.Linq;
using System.Reflection;
using Campus.API.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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

        var authorizeAttr = method.GetCustomAttribute<AuthorizeAttribute>();
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
            .FirstOrDefault(m => m.Name == actionName);

        Assert.NotNull(method);

        var authorizeAttr = method.GetCustomAttribute<AuthorizeAttribute>();
        Assert.True(authorizeAttr == null || authorizeAttr.Roles != "Admin");
    }
}
