export interface BuildingDto {
  id: string;
  campusId: string;
  name: string;
  floorsCount: number;
  latitude: number;
  longitude: number;
  categoryId?: string | null;
  openTime?: string | null;
  closeTime?: string | null;
  photoUrl?: string | null;
  categoryName?: string | null;
  categoryIcon?: string | null;
}
