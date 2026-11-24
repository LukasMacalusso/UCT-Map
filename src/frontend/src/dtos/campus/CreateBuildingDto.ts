export interface CreateBuildingDto {
  campusId: string;
  name: string;
  floorsCount: number;
  latitude: number;
  longitude: number;
  categoryId?: string | null;
  openTime?: string | null;
  closeTime?: string | null;
  photoUrl?: string | null;
}
