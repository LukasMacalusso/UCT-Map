import { keepPreviousData, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { queryKeys } from "../api/queryKeys";
import type { ReportPageDto } from "../dtos/incident/reports/ReportPageDto";
import type { ReportSearchParams } from "../dtos/incident/reports/ReportSearchParams";
import { incidentService } from "../services/incidentService";
import type { ReportDto } from "../dtos/incident/reports/ReportDto";
import type { CreateReportRequestDto } from "../dtos/incident/reports/CreateReportRequestDto";
import type { TicketStatus } from "../constants/ticketStatus";
import type { ComplaintStatus } from "../constants/complaintStatus";

export const useReports = (params: ReportSearchParams = {}, enabled = true) => {
  return useQuery<ReportPageDto, Error>({
    queryKey: queryKeys.reports.list(params),
    queryFn: () => incidentService.searchReports(params),
    placeholderData: keepPreviousData,
    enabled,
  });
};

export const useReport = (id?: string) => {
  return useQuery<ReportDto, Error>({
    queryKey: queryKeys.reports.detail(id ?? ''),
    queryFn: () => incidentService.getReport(id!),
    enabled: !!id,
  });
};

export const useCreateReport = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (payload: CreateReportRequestDto) => incidentService.createReport(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.reports.all }),
  });
};

export const useUpdateReportStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      status,
      complaintStatus,
    }: {
      id: string;
      status: TicketStatus;
      complaintStatus?: ComplaintStatus;
    }) => incidentService.updateReportStatus(id, status, complaintStatus),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.reports.all }),
  });
};

export const useDeleteReport = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => incidentService.deleteReport(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: queryKeys.reports.all }),
  });
};
