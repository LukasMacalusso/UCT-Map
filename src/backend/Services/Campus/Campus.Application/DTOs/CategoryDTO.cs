using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record CategoryDto(
    Guid Id,
    string Name,
    string Icon,
    string? Description,
    int Order
);

public record CreateCategoryDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Icon is mandatory.")]
    [StringLength(100, ErrorMessage = "Icon cannot exceed 100 characters.")]
    string Icon,

    [MaxLength(250, ErrorMessage = "Description cannot exceed 250 characters.")]
    string? Description = null,

    int Order = 0
);

public record UpdateCategoryDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    [Required(ErrorMessage = "Icon is mandatory.")]
    [StringLength(100, ErrorMessage = "Icon cannot exceed 100 characters.")]
    string Icon,

    [MaxLength(250, ErrorMessage = "Description cannot exceed 250 characters.")]
    string? Description = null,

    int Order = 0
);

public record ReorderItemDto(
    [Required(ErrorMessage = "Id is required.")]
    Guid Id,

    [Required(ErrorMessage = "Order is required.")]
    int Order
);
