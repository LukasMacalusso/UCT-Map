export interface StructureDto {
  id: string;
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}

export interface CreateStructureDto {
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}

export interface UpdateStructureDto {
  campusId: string;
  categoryId?: string | null;
  name: string;
  latitude: number;
  longitude: number;
}
