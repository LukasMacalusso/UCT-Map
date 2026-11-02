import { toApiError } from "../api/apiError";
import httpClient from "../api/httpClient";
import type { CreateMeetingRequest } from "../dtos/schedule/CreateMeetingRequest";
import type { MeetingDto, MeetingStatusName } from "../dtos/schedule/MeetingDto";
import type { OfficeHourDto } from "../dtos/schedule/OfficeHourDto";
import type { TeacherAvailabilityDto } from "../dtos/schedule/TeacherAvailabilityDto";
import type { TeacherWorkloadDto } from "../dtos/schedule/TeacherWorkloadDto";

const CREATE_MEETING_ERRORS: Record<number, string> = {
  400: "Los datos de la reunión no son válidos",
  409: "El horario seleccionado ya no está disponible. Elige otro bloque",
  500: "Error interno del servidor. Intenta más tarde",
};

const UPDATE_MEETING_STATUS_ERRORS: Record<number, string> = {
  400: "El estado seleccionado no es válido",
  403: "No tienes permiso para cambiar el estado de esta reunión",
  404: "La reunión ya no existe",
  409: "El estado actual de la reunión no permite ese cambio",
};

// Schedule.md convention: "Dates use ISO 8601 without time zone: 2026-10-12T15:30:00"
const toScheduleDateTime = (isoOrDate: string): string =>
  isoOrDate.replace(/\.\d{3}Z$/i, "").replace(/Z$/i, "");

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
        {
          params: {
            from: toScheduleDateTime(from),
            to: toScheduleDateTime(to),
          },
        }
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
        params: {
          teacherId,
          from: from ? toScheduleDateTime(from) : undefined,
          to: to ? toScheduleDateTime(to) : undefined,
        },
      });
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar las reuniones");
    }
  },

  async createMeeting(payload: CreateMeetingRequest): Promise<MeetingDto> {
    try {
      const { data } = await httpClient.post<MeetingDto>("/api/schedule/meetings", {
        ...payload,
        scheduledAt: toScheduleDateTime(payload.scheduledAt),
      });
      return data;
    } catch (error) {
      throw toApiError(error, "Error al agendar la reunión", CREATE_MEETING_ERRORS);
    }
  },

  async updateMeetingStatus(
    id: string,
    status: MeetingStatusName
  ): Promise<MeetingDto> {
    try {
      const { data } = await httpClient.patch<MeetingDto>(
        `/api/schedule/meetings/${id}/status`,
        { status }
      );
      return data;
    } catch (error) {
      throw toApiError(
        error,
        "Error al actualizar el estado de la reunión",
        UPDATE_MEETING_STATUS_ERRORS,
      );
    }
  },
};
