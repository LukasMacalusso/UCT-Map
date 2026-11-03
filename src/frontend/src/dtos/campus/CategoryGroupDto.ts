export interface CategoryGroupDto {
  id: string;
  name: string;
  order: number;
}

export interface CreateCategoryGroupDto {
  name: string;
  order?: number;
}

export interface UpdateCategoryGroupDto {
  name: string;
  order?: number;
}

export interface ReorderItemDto {
  id: string;
  order: number;
}
