export interface UpdateStructureDto {
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}
