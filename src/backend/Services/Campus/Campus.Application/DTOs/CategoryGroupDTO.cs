using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record CategoryGroupDto(
    Guid Id,
    string Name
);

public record CreateCategoryGroupDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name
);

public record UpdateCategoryGroupDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name
);
