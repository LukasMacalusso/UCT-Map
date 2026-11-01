import { toApiError } from "../api/apiError";
import httpClient from "../api/httpClient";
import type { CreateMeetingRequest } from "../dtos/schedule/CreateMeetingRequest";
import type { MeetingDto } from "../dtos/schedule/MeetingDto";
import type { OfficeHourDto } from "../dtos/schedule/OfficeHourDto";
import type { TeacherAvailabilityDto } from "../dtos/schedule/TeacherAvailabilityDto";
import type { TeacherWorkloadDto } from "../dtos/schedule/TeacherWorkloadDto";

const CREATE_MEETING_ERRORS: Record<number, string> = {
  400: "Los datos de la reunión no son válidos",
  409: "El horario seleccionado ya no está disponible. Elige otro bloque",
  500: "Error interno del servidor. Intenta más tarde",
};

export const scheduleService = {
  async getAvailability(teacherId: string): Promise<TeacherAvailabilityDto> {
    try {
      const { data } = await httpClient.get<TeacherAvailabilityDto>(
        `/api/schedule/teachers/${teacherId}/availability`
      );
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar la disponibilidad");
    }
  },

  async getWorkload(
    teacherId: string,
    from: string,
    to: string
  ): Promise<TeacherWorkloadDto> {
    try {
      const { data } = await httpClient.get<TeacherWorkloadDto>(
        `/api/schedule/teachers/${teacherId}/workload`,
        { params: { from, to } }
      );
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar la carga de trabajo");
    }
  },

  async getOfficeHours(teacherId?: string): Promise<OfficeHourDto[]> {
    try {
      const { data } = await httpClient.get<OfficeHourDto[]>("/api/schedule/office-hours", {
        params: { teacherId },
      });
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar los horarios de atención");
    }
  },

  async getMeetings(
    teacherId?: string,
    from?: string,
    to?: string
  ): Promise<MeetingDto[]> {
    try {
      const { data } = await httpClient.get<MeetingDto[]>("/api/schedule/meetings", {
        params: { teacherId, from, to },
      });
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar las reuniones");
    }
  },

  async createMeeting(payload: CreateMeetingRequest): Promise<MeetingDto> {
    try {
      const { data } = await httpClient.post<MeetingDto>("/api/schedule/meetings", payload);
      return data;
    } catch (error) {
      throw toApiError(error, "Error al agendar la reunión", CREATE_MEETING_ERRORS);
    }
  },
};
