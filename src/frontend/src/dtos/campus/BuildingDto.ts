export interface BuildingDto {
  id: string;
  campusId: string;
  name: string;
  floorsCount: number;
  latitude: number;
  longitude: number;
  openTime?: string | null;
  closeTime?: string | null;
  services?: string | null;
}
