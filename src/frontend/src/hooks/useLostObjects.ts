import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { LostObjectDto } from "../dtos/incident/objects/LostObjectDto";
import type { LostObjectPageDto } from "../dtos/incident/objects/LostObjectPageDto";
import type { LostObjectSearchParams } from "../dtos/incident/objects/LostObjectSearchParams";
import { queryKeys } from "../api/queryKeys";
import { incidentService } from "../services/incidentService";
import type { CreateLostObjectRequestDto } from "../dtos/incident/objects/CreateLostObjectRequestDto";
import type { LostObjectStatus } from "../constants/lostObjectsStatus";

export const useLostObjects = (params: LostObjectSearchParams = {}, enabled = true) => {
  return useQuery<LostObjectPageDto, Error>({
    queryKey: queryKeys.lostObjects.list(params),
    queryFn: () => incidentService.searchLostObjects(params),
    placeholderData: keepPreviousData,
    enabled,
  });
};

export const useLostObjectsByIds = (ids: string[], enabled = true) => {
  const uniqueIds = Array.from(new Set(ids.filter(Boolean)));
  return useQuery<LostObjectDto[], Error>({
    queryKey: [...queryKeys.lostObjects.all, "by-ids", uniqueIds],
    queryFn: async () => {
      const results = await Promise.allSettled(
        uniqueIds.map((id) => incidentService.getLostObject(id))
      );
      return results
        .filter((res): res is PromiseFulfilledResult<LostObjectDto> => res.status === "fulfilled")
        .map((res) => res.value);
    },
    enabled: enabled && uniqueIds.length > 0,
  });
};

export const useCreateLostObject = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateLostObjectRequestDto) => incidentService.createLostObject(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.lostObjects.all });
      queryClient.invalidateQueries({ queryKey: queryKeys.reports.all });
    },
  });
};

export const useUpdateLostObjectStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: LostObjectStatus }) =>
      incidentService.updateLostObjectStatus(id, status),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.lostObjects.all }),
  });
};

export const useDeleteLostObject = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => incidentService.deleteLostObject(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.lostObjects.all }),
  });
};
