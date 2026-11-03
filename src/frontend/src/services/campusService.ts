import httpClient from '../api/httpClient';
import { toApiError } from '../api/apiError';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { CampusDto } from '../dtos/campus/CampusDto';
import type { CreateCampusDto } from '../dtos/campus/CreateCampusDto';
import type { UpdateCampusDto } from '../dtos/campus/UpdateCampusDto';
import type { RoomDto } from '../dtos/campus/RoomDto';
import type { CreateRoomDto } from '../dtos/campus/CreateRoomDto';
import type { UpdateRoomDto } from '../dtos/campus/UpdateRoomDto';
import type { StructureDto } from '../dtos/campus/StructureDto';
import type { CreateStructureDto } from '../dtos/campus/CreateStructureDto';
import type { UpdateStructureDto } from '../dtos/campus/UpdateStructureDto';
import type { BuildingDto } from '../dtos/campus/BuildingDto';
import type { CreateBuildingDto } from '../dtos/campus/CreateBuildingDto';
import type { UpdateBuildingDto } from '../dtos/campus/UpdateBuildingDto';
import type { CategoryDto } from '../dtos/campus/CategoryDto';
import type { CreateCategoryDto } from '../dtos/campus/CreateCategoryDto';
import type { UpdateCategoryDto } from '../dtos/campus/UpdateCategoryDto';
import type { ReorderItemDto } from '../dtos/campus/ReorderItemDto';

export const campusService = {
  getCampuses: async (): Promise<CampusDto[]> => {
    try {
      const { data } = await httpClient.get<CampusDto[]>('/api/campus/campuses');
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar los campus');
    }
  },

  createCampus: async (payload: CreateCampusDto): Promise<CampusDto> => {
    try {
      const { data } = await httpClient.post<CampusDto>('/api/campus/campuses', payload);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al crear el campus');
    }
  },

  deleteCampus: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/campus/campuses/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar el campus');
    }
  },

  updateCampus: async (id: string, payload: UpdateCampusDto): Promise<void> => {
    try {
      await httpClient.put(`/api/campus/campuses/${id}`, payload);
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el campus');
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

  getStructures: async (campusId?: string): Promise<StructureDto[]> => {
    try {
      const { data } = await httpClient.get<StructureDto[]>('/api/campus/structures', {
        params: campusId ? { campusId } : undefined,
      });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar las estructuras');
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

  createRoom: async (payload: CreateRoomDto): Promise<RoomDto> => {
    try {
      const { data } = await httpClient.post<RoomDto>('/api/campus/rooms', payload);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al crear la sala');
    }
  },

  updateRoom: async (id: string, payload: UpdateRoomDto): Promise<void> => {
    try {
      await httpClient.put(`/api/campus/rooms/${id}`, payload);
    } catch (error) {
      throw toApiError(error, 'Error al actualizar la sala');
    }
  },

  deleteRoom: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/campus/rooms/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar la sala');
    }
  },

  createStructure: async (payload: CreateStructureDto): Promise<StructureDto> => {
    try {
      const { data } = await httpClient.post<StructureDto>('/api/campus/structures', payload);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al crear la estructura');
    }
  },

  updateStructure: async (id: string, payload: UpdateStructureDto): Promise<void> => {
    try {
      await httpClient.put(`/api/campus/structures/${id}`, payload);
    } catch (error) {
      throw toApiError(error, 'Error al actualizar la estructura');
    }
  },

  deleteStructure: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/campus/structures/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar la estructura');
    }
  },

  createBuilding: async (payload: CreateBuildingDto): Promise<BuildingDto> => {
    try {
      const { data } = await httpClient.post<BuildingDto>('/api/campus/buildings', payload);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al crear el edificio');
    }
  },

  updateBuilding: async (id: string, payload: UpdateBuildingDto): Promise<void> => {
    try {
      await httpClient.put(`/api/campus/buildings/${id}`, payload);
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el edificio');
    }
  },

  updateBuildingLocation: async (id: string, latitude: number, longitude: number): Promise<void> => {
    try {
      await httpClient.patch(`/api/campus/buildings/${id}/location`, { latitude, longitude });
    } catch (error) {
      throw toApiError(error, 'Error al actualizar la ubicación del edificio');
    }
  },

  updateStructureLocation: async (id: string, latitude: number, longitude: number): Promise<void> => {
    try {
      await httpClient.patch(`/api/campus/structures/${id}/location`, { latitude, longitude });
    } catch (error) {
      throw toApiError(error, 'Error al actualizar la ubicación de la estructura');
    }
  },

  deleteBuilding: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/campus/buildings/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar el edificio');
    }
  },

  // Categories (Filters)
  getCategories: async (): Promise<CategoryDto[]> => {
    try {
      const { data } = await httpClient.get<CategoryDto[]>('/api/campus/categories');
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar los filtros');
    }
  },

  createCategory: async (payload: CreateCategoryDto): Promise<CategoryDto> => {
    try {
      const { data } = await httpClient.post<CategoryDto>('/api/campus/categories', payload);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al crear el filtro');
    }
  },

  updateCategory: async (id: string, payload: UpdateCategoryDto): Promise<void> => {
    try {
      await httpClient.put(`/api/campus/categories/${id}`, payload);
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el filtro');
    }
  },

  reorderCategories: async (items: ReorderItemDto[]): Promise<void> => {
    try {
      await httpClient.put('/api/campus/categories/reorder', items);
    } catch (error) {
      throw toApiError(error, 'Error al reordenar los filtros');
    }
  },

  deleteCategory: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/campus/categories/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar el filtro');
    }
  },
};
