export interface CreateCategoryDto {
  name: string;
  icon: string;
  description?: string | null;
  order?: number;
}
