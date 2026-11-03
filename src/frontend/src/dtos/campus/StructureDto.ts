export interface StructureDto {
  id: string;
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}
