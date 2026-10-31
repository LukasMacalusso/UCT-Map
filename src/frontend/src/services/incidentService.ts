import { toApiError } from "../api/apiError";
import httpClient from "../api/httpClient";
import type { ComplaintStatus } from "../constants/complaintStatus";
import type { LostObjectStatus } from "../constants/lostObjectsStatus";
import type { TicketStatus } from "../constants/ticketStatus";
import type { CreateLostObjectRequestDto } from "../dtos/incident/objects/CreateLostObjectRequestDto";
import type { LostObjectPageApiDto } from "../dtos/incident/objects/LostObjectPageApiDto";
import type { LostObjectPageDto } from "../dtos/incident/objects/LostObjectPageDto";
import type { LostObjectSearchParams } from "../dtos/incident/objects/LostObjectSearchParams";
import { mapLostObject } from "../dtos/incident/objects/MapLostObjects";
import type { CreateReportRequestDto } from "../dtos/incident/reports/CreateReportRequestDto";
import type { ReportDto } from "../dtos/incident/reports/ReportDto";
import type { ReportPageDto } from "../dtos/incident/reports/ReportPageDto";
import type { ReportSearchParams } from "../dtos/incident/reports/ReportSearchParams";

export const incidentService = {
  // ---------- Reports ----------
  searchReports: async (params: ReportSearchParams = {}): Promise<ReportPageDto> => {
    try {
      const { data } = await httpClient.get<ReportPageDto>('/api/incident/reports', { params });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar los reportes');
    }
  },

  getReport: async (id: string): Promise<ReportDto> => {
    try {
      const { data } = await httpClient.get<ReportDto>(`/api/incident/reports/${id}`);
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al cargar el reporte');
    }
  },

  createReport: async (payload: CreateReportRequestDto): Promise<string> => {
    try {
      const { data } = await httpClient.post<{ id: string }>('/api/incident/reports', payload);
      return data.id;
    } catch (error) {
      throw toApiError(error, 'Error al crear el reporte');
    }
  },

  updateReportStatus: async (
    id: string,
    status: TicketStatus,
    complaintStatus?: ComplaintStatus,
  ): Promise<void> => {
    try {
      await httpClient.patch(`/api/incident/reports/${id}/report/status`, {
        status,
        complainStatus: complaintStatus,
      });
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el estado del reporte');
    }
  },

  deleteReport: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/incident/reports/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar el reporte');
    }
  },

  // ---------- Lost objects ----------
  searchLostObjects: async (params: LostObjectSearchParams = {}): Promise<LostObjectPageDto> => {
    try {
      const { data } = await httpClient.get<LostObjectPageApiDto>('/api/incident/lost-objects', {
        params,
      });
      return { ...data, items: data.items.map(mapLostObject) };
    } catch (error) {
      throw toApiError(error, 'Error al cargar los objetos perdidos');
    }
  },

  getLostObject: async (id: string): Promise<void> => {
    try {
      await httpClient.get(`/api/incident/lost-objects/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al cargar el objeto perdido');
    }
  },

  createLostObject: async (payload: CreateLostObjectRequestDto): Promise<string> => {
    try {
      const { data } = await httpClient.post<{ id: string }>(
        '/api/incident/lost-objects',
        { ...payload, photoUrl: payload.photoUrl ?? '' },
      );
      return data.id;
    } catch (error) {
      throw toApiError(error, 'Error al registrar el objeto perdido');
    }
  },

  updateLostObjectStatus: async (id: string, status: LostObjectStatus): Promise<void> => {
    try {
      await httpClient.patch(`/api/incident/lost-objects/${id}/lost/status`, { status });
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el estado del objeto');
    }
  },

  deleteLostObject: async (id: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/incident/lost-objects/${id}`);
    } catch (error) {
      throw toApiError(error, 'Error al eliminar el objeto perdido');
    }
  },
};
