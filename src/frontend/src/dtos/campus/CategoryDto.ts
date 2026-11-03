export interface CategoryDto {
  id: string;
  name: string;
  icon: string;
  description?: string | null;
  order: number;
}

export interface CreateCategoryDto {
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}

export interface UpdateCategoryDto {
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}

export interface ReorderItemDto {
  id: string;
  order: number;
}
