using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record CategoryDto(
    Guid Id,
    Guid CategoryGroupId,
    string Name,
    string Icon,
    string? Description
);

public record CreateCategoryDto(
    [Required(ErrorMessage = "CategoryGroupId is required.")]
    Guid CategoryGroupId,

    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Icon is mandatory.")]
    [StringLength(100, ErrorMessage = "Icon cannot exceed 100 characters.")]
    string Icon,

    [MaxLength(250, ErrorMessage = "Description cannot exceed 250 characters.")]
    string? Description = null
);

public record UpdateCategoryDto(
    [Required(ErrorMessage = "CategoryGroupId is required.")]
    Guid CategoryGroupId,

    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Icon is mandatory.")]
    [StringLength(100, ErrorMessage = "Icon cannot exceed 100 characters.")]
    string Icon,

    [MaxLength(250, ErrorMessage = "Description cannot exceed 250 characters.")]
    string? Description = null
);
