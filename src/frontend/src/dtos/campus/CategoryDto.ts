export interface CategoryDto {
  id: string;
  categoryGroupId: string;
  name: string;
  icon: string;
  description?: string | null;
  order: number;
}

export interface CreateCategoryDto {
  categoryGroupId: string;
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}

export interface UpdateCategoryDto {
  categoryGroupId: string;
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}
