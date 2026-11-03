export interface UpdateCategoryDto {
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}
