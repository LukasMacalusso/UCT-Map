import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { queryKeys } from '../api/queryKeys';
import { campusService } from '../services/campusService';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { CampusDto } from '../dtos/campus/CampusDto';
import type { CreateCampusDto } from '../dtos/campus/CreateCampusDto';
import type { UpdateCampusDto } from '../dtos/campus/UpdateCampusDto';
import type { RoomDto, CreateRoomDto, UpdateRoomDto } from '../dtos/campus/RoomDto';
import type { StructureDto, CreateStructureDto, UpdateStructureDto } from '../dtos/campus/StructureDto';
import type { BuildingDto, CreateBuildingDto, UpdateBuildingDto } from '../dtos/campus/BuildingDto';
import type {
  CategoryGroupDto,
  CreateCategoryGroupDto,
  UpdateCategoryGroupDto,
  ReorderItemDto,
} from '../dtos/campus/CategoryGroupDto';
import type {
  CategoryDto,
  CreateCategoryDto,
  UpdateCategoryDto,
} from '../dtos/campus/CategoryDto';

export const useCampuses = () => {
  return useQuery<CampusDto[], Error>({
    queryKey: queryKeys.campuses,
    queryFn: () => campusService.getCampuses(),
    staleTime: 1000 * 60 * 5,
  });
};

export const useCreateCampus = () => {
  const queryClient = useQueryClient();

  return useMutation<CampusDto, Error, CreateCampusDto>({
    mutationFn: (payload) => campusService.createCampus(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.campuses }),
  });
};

export const useUpdateCampus = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateCampusDto }>({
    mutationFn: ({ id, payload }) => campusService.updateCampus(id, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.campuses }),
  });
};

export const useDeleteCampus = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteCampus(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.campuses }),
  });
};

export const useBuildingLocations = (campusId?: string, enabled = true) => {
  return useQuery<BuildingLocationDto[], Error>({
    queryKey: queryKeys.buildingLocations(campusId),
    queryFn: () => campusService.getBuildingLocations(campusId),
    enabled,
    staleTime: 1000 * 60 * 5,
  });
};

export const useSearchRooms = (term: string) => {
  return useQuery<RoomDto[], Error>({
    queryKey: queryKeys.roomSearch(term),
    queryFn: () => campusService.searchRooms(term),
    enabled: term.trim().length > 2,
    staleTime: 1000 * 60,
  });
};

export const useStructures = (campusId?: string, enabled = true) => {
  return useQuery<StructureDto[], Error>({
    queryKey: queryKeys.structures(campusId),
    queryFn: () => campusService.getStructures(campusId),
    enabled,
    staleTime: 1000 * 60 * 5,
  });
};

export const useBuildingRooms = (buildingId?: string) => {
  return useQuery<RoomDto[], Error>({
    queryKey: queryKeys.buildingRooms(buildingId),
    queryFn: () => campusService.getBuildingRooms(buildingId!),
    enabled: !!buildingId,
    staleTime: 1000 * 60 * 5,
  });
};

// Room mutations
export const useCreateRoom = () => {
  const queryClient = useQueryClient();

  return useMutation<RoomDto, Error, CreateRoomDto>({
    mutationFn: (payload) => campusService.createRoom(payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.buildingRooms(variables.buildingId) });
      queryClient.invalidateQueries({ queryKey: ['roomSearch'] });
    },
  });
};

export const useUpdateRoom = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateRoomDto }>({
    mutationFn: ({ id, payload }) => campusService.updateRoom(id, payload),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.buildingRooms(variables.payload.buildingId) });
      queryClient.invalidateQueries({ queryKey: ['roomSearch'] });
    },
  });
};

export const useDeleteRoom = (buildingId?: string) => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteRoom(id),
    onSuccess: () => {
      if (buildingId) {
        queryClient.invalidateQueries({ queryKey: queryKeys.buildingRooms(buildingId) });
      }
      queryClient.invalidateQueries({ queryKey: ['roomSearch'] });
    },
  });
};

// Building mutations
export const useCreateBuilding = () => {
  const queryClient = useQueryClient();

  return useMutation<BuildingDto, Error, CreateBuildingDto>({
    mutationFn: (payload) => campusService.createBuilding(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buildingLocations'] });
    },
  });
};

export const useUpdateBuilding = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateBuildingDto }>({
    mutationFn: ({ id, payload }) => campusService.updateBuilding(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buildingLocations'] });
    },
  });
};

export const useDeleteBuilding = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteBuilding(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['buildingLocations'] });
    },
  });
};

// Structure mutations
export const useCreateStructure = () => {
  const queryClient = useQueryClient();

  return useMutation<StructureDto, Error, CreateStructureDto>({
    mutationFn: (payload) => campusService.createStructure(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.structures() });
    },
  });
};

export const useUpdateStructure = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateStructureDto }>({
    mutationFn: ({ id, payload }) => campusService.updateStructure(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.structures() });
    },
  });
};

export const useDeleteStructure = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteStructure(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.structures() });
    },
  });
};

// Category Groups (Filter Groups)
export const useCategoryGroups = () => {
  return useQuery<CategoryGroupDto[], Error>({
    queryKey: queryKeys.categoryGroups,
    queryFn: () => campusService.getCategoryGroups(),
    staleTime: 1000 * 60 * 5,
  });
};

export const useCreateCategoryGroup = () => {
  const queryClient = useQueryClient();

  return useMutation<CategoryGroupDto, Error, CreateCategoryGroupDto>({
    mutationFn: (payload) => campusService.createCategoryGroup(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categoryGroups }),
  });
};

export const useUpdateCategoryGroup = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateCategoryGroupDto }>({
    mutationFn: ({ id, payload }) => campusService.updateCategoryGroup(id, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categoryGroups }),
  });
};

export const useReorderCategoryGroups = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, ReorderItemDto[]>({
    mutationFn: (items) => campusService.reorderCategoryGroups(items),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categoryGroups }),
  });
};

export const useDeleteCategoryGroup = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteCategoryGroup(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.categoryGroups });
      queryClient.invalidateQueries({ queryKey: queryKeys.categories });
    },
  });
};

// Categories (Filters)
export const useCategories = () => {
  return useQuery<CategoryDto[], Error>({
    queryKey: queryKeys.categories,
    queryFn: () => campusService.getCategories(),
    staleTime: 1000 * 60 * 5,
  });
};

export const useCreateCategory = () => {
  const queryClient = useQueryClient();

  return useMutation<CategoryDto, Error, CreateCategoryDto>({
    mutationFn: (payload) => campusService.createCategory(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categories }),
  });
};

export const useUpdateCategory = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, { id: string; payload: UpdateCategoryDto }>({
    mutationFn: ({ id, payload }) => campusService.updateCategory(id, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categories }),
  });
};

export const useReorderCategories = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, ReorderItemDto[]>({
    mutationFn: (items) => campusService.reorderCategories(items),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categories }),
  });
};

export const useDeleteCategory = () => {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: (id) => campusService.deleteCategory(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.categories }),
  });
};
