using System;

namespace Campus.Application.DTOs;

public record CategoryGroupDto(
    Guid Id,
    string Name
);

public record CreateCategoryGroupDto(
    string Name
);

public record UpdateCategoryGroupDto(
    string Name
);
