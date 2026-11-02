using System;
using System.ComponentModel.DataAnnotations;

namespace Campus.Application.DTOs;

public record CategoryGroupDto(
    Guid Id,
    string Name,
    int Order
);

public record CreateCategoryGroupDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    int Order = 0
);

public record UpdateCategoryGroupDto(
    [Required(ErrorMessage = "Name is mandatory.")]
    [StringLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    string Name,

    int Order = 0
);

public record ReorderItemDto(
    [Required(ErrorMessage = "Id is required.")]
    Guid Id,

    [Required(ErrorMessage = "Order is required.")]
    int Order
);
