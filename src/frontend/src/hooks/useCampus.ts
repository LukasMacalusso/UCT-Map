import { useQuery } from '@tanstack/react-query';
import { campusService } from '../services/campusService';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { RoomDto } from '../dtos/campus/RoomDto';

export const useBuildingLocations = (campusId?: string) => {
  return useQuery<BuildingLocationDto[], Error>({
    queryKey: ['buildingLocations', campusId],
    queryFn: () => campusService.getBuildingLocations(campusId),
    staleTime: 1000 * 60 * 5, // Cache the locations for 5 minutes since they rarely change
  });
};

export const useSearchRooms = (term: string) => {
  return useQuery<RoomDto[], Error>({
    queryKey: ['searchRooms', term],
    queryFn: () => campusService.searchRooms(term),
    enabled: term.trim().length > 2, // Only trigger search if term is at least 3 characters
    staleTime: 1000 * 60, // Cache search results for 1 minute
  });
};

export const useBuildingRooms = (buildingId?: string) => {
  return useQuery<RoomDto[], Error>({
    queryKey: ['buildingRooms', buildingId],
    queryFn: () => campusService.getBuildingRooms(buildingId!),
    enabled: !!buildingId,
    staleTime: 1000 * 60 * 5, // Cache for 5 minutes
  });
};
