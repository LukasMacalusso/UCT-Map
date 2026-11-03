export interface CategoryDto {
  id: string;
  name: string;
  icon: string;
  description?: string | null;
  order: number;
}
