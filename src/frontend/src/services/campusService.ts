import httpClient from '../api/httpClient';
import { toApiError } from '../api/apiError';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { CampusDto } from '../dtos/campus/CampusDto';
import type { RoomDto } from '../dtos/campus/RoomDto';

export const campusService = {
  getCampuses: async (): Promise<CampusDto[]> => {
    try {
      const { data } = await httpClient.get<CampusDto[]>('/api/campus/campuses');
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar los campus');
    }
  },

  getBuildingLocations: async (campusId?: string): Promise<BuildingLocationDto[]> => {
    try {
      const { data } = await httpClient.get<BuildingLocationDto[]>('/api/campus/buildings/locations', {
        params: campusId ? { campusId } : undefined,
      });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar las ubicaciones de los edificios');
    }
  },

  searchRooms: async (term: string): Promise<RoomDto[]> => {
    if (!term.trim()) return [];

    try {
      const { data } = await httpClient.get<RoomDto[]>('/api/campus/rooms/search', {
        params: { term },
      });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al buscar salas');
    }
  },

  getBuildingRooms: async (buildingId: string): Promise<RoomDto[]> => {
    try {
      const { data } = await httpClient.get<RoomDto[]>(`/api/campus/buildings/${buildingId}/rooms`);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar las salas del edificio');
    }
  },
};
