using System;

namespace Campus.Application.DTOs;

public record CategoryDto(
    Guid Id,
    Guid CategoryGroupId,
    string Name,
    string Icon,
    string? Description
);

public record CreateCategoryDto(
    Guid CategoryGroupId,
    string Name,
    string Icon,
    string? Description = null
);

public record UpdateCategoryDto(
    Guid CategoryGroupId,
    string Name,
    string Icon,
    string? Description = null
);
