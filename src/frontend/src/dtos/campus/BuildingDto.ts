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

export interface CreateBuildingDto {
  campusId: string;
  name: string;
  floorsCount: number;
  latitude: number;
  longitude: number;
  openTime?: string | null;
  closeTime?: string | null;
  services?: string | null;
}

export interface UpdateBuildingDto {
  campusId: string;
  name: string;
  floorsCount: number;
  latitude: number;
  longitude: number;
  openTime?: string | null;
  closeTime?: string | null;
  services?: string | null;
}
