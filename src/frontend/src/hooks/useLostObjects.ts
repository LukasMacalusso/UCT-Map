import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
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

export const useCreateLostObject = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateLostObjectRequestDto) => incidentService.createLostObject(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.lostObjects.all }),
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
