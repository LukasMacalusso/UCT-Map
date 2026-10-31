import { useQuery } from '@tanstack/react-query';
import { queryKeys } from '../api/queryKeys';
import { campusService } from '../services/campusService';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { CampusDto } from '../dtos/campus/CampusDto';
import type { RoomDto } from '../dtos/campus/RoomDto';
import type { StructureDto } from '../dtos/campus/StructureDto';

export const useCampuses = () => {
  return useQuery<CampusDto[], Error>({
    queryKey: queryKeys.campuses,
    queryFn: () => campusService.getCampuses(),
    staleTime: 1000 * 60 * 5,
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
