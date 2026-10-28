import httpClient from '../api/httpClient';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { CampusDto } from '../dtos/campus/CampusDto';
import type { RoomDto } from '../dtos/campus/RoomDto';

export const campusService = {
  getCampuses: async (): Promise<CampusDto[]> => {
    try {
      const response = await httpClient.get<CampusDto[]>('/api/campus/campuses');
      return response.data;
    } catch (err) {
      throw new Error('Error al cargar los campus', { cause: err });
    }
  },

  getBuildingLocations: async (campusId?: string): Promise<BuildingLocationDto[]> => {
    try {
      const url = campusId 
        ? `/api/campus/buildings/locations?campusId=${campusId}` 
        : '/api/campus/buildings/locations';
      const response = await httpClient.get<BuildingLocationDto[]>(url);
      return response.data;
    } catch (err: any) {
      throw new Error('Error al cargar las ubicaciones de los edificios');
    }
  },

  searchRooms: async (term: string): Promise<RoomDto[]> => {
    if (!term || term.trim() === '') return [];
    
    try {
      const response = await httpClient.get<RoomDto[]>(`/api/campus/rooms/search?term=${encodeURIComponent(term)}`);
      return response.data;
    } catch (err: any) {
      throw new Error('Error al buscar salas');
    }
  },

  getBuildingRooms: async (buildingId: string): Promise<RoomDto[]> => {
    try {
      const response = await httpClient.get<RoomDto[]>(`/api/campus/buildings/${buildingId}/rooms`);
      return response.data;
    } catch (err: any) {
      throw new Error('Error al cargar las salas del edificio');
    }
  }
};
