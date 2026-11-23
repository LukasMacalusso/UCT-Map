export interface BuildingMetadataDto {
  campusId: string;
  categoryId?: string | null;
  floorsCount: number;
  schedule?: string;
  services?: string[];
}
