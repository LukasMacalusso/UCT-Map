using System;

namespace Schedule.Application.Common;

// The authenticated user making the request, taken from the JWT already validated by the API.
public sealed record Requester(Guid UserId, bool IsAdmin, bool IsTeacher = false)
{
    public const string AdminRole = "Admin";
    public const string TeacherRole = "Teacher";

    public bool CanAccess(Guid ownerRefId) => IsAdmin || UserId == ownerRefId;

    // Office hours belong to teachers; students or other roles cannot have them.
    public bool CanManageOfficeHours => IsAdmin || IsTeacher;
}
