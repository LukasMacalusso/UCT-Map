export interface CreateStructureDto {
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}
