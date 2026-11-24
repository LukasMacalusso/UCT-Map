import { toApiError } from "../api/apiError";
import httpClient from "../api/httpClient";
import type { CreateMeetingRequest } from "../dtos/schedule/CreateMeetingRequest";
import type { CreateOfficeHourRequest } from "../dtos/schedule/CreateOfficeHourRequest";
import type { MeetingDto, MeetingStatusName } from "../dtos/schedule/MeetingDto";
import type { OfficeHourDto } from "../dtos/schedule/OfficeHourDto";
import type { RescheduleMeetingRequest } from "../dtos/schedule/RescheduleMeetingRequest";
import type { StudentMeetingsDto } from "../dtos/schedule/StudentMeetingsDto";
import type { TeacherAvailabilityDto } from "../dtos/schedule/TeacherAvailabilityDto";
import type { TeacherWorkloadDto } from "../dtos/schedule/TeacherWorkloadDto";
import type { UpdateOfficeHourRequest } from "../dtos/schedule/UpdateOfficeHourRequest";
import { DAY_INDEX } from "../utils/schedule";

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

const RESCHEDULE_MEETING_ERRORS: Record<number, string> = {
  400: "Los datos para reagendar la reunión no son válidos",
  403: "No tienes permiso para reagendar esta reunión",
  404: "La reunión ya no existe",
  409: "El nuevo horario no está disponible o el estado de la reunión no permite reagendar",
};

const CANCEL_MEETING_ERRORS: Record<number, string> = {
  403: "No tienes permiso para cancelar esta reunión",
  404: "La reunión ya no existe",
  409: "El estado actual de la reunión no permite cancelarla",
};

const CREATE_OFFICE_HOUR_ERRORS: Record<number, string> = {
  400: "Los datos del horario no son válidos",
  401: "Tu sesión expiró. Inicia sesión nuevamente",
  403: "No tienes permiso para crear este horario",
  409: "El bloque de atención se solapa con otro horario existente",
  500: "Error interno del servidor. Intenta más tarde",
};

const UPDATE_OFFICE_HOUR_ERRORS: Record<number, string> = {
  400: "Los datos del horario no son válidos",
  401: "Tu sesión expiró. Inicia sesión nuevamente",
  403: "No tienes permiso para editar este horario",
  404: "El bloque de atención ya no existe",
  409: "El bloque de atención se solapa con otro horario existente",
  500: "Error interno del servidor. Intenta más tarde",
};

const DELETE_OFFICE_HOUR_ERRORS: Record<number, string> = {
  401: "Tu sesión expiró. Inicia sesión nuevamente",
  403: "No tienes permiso para eliminar este horario",
  404: "El bloque de atención ya no existe",
  500: "Error interno del servidor. Intenta más tarde",
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

  async createOfficeHour(payload: CreateOfficeHourRequest): Promise<OfficeHourDto> {
    try {
      const dayOfWeek =
        typeof payload.dayOfWeek === 'string' && payload.dayOfWeek in DAY_INDEX
          ? DAY_INDEX[payload.dayOfWeek as keyof typeof DAY_INDEX]
          : payload.dayOfWeek;

      const { data } = await httpClient.post<OfficeHourDto>(
        "/api/schedule/office-hours",
        {
          ...payload,
          dayOfWeek,
        },
      );
      return data;
    } catch (error) {
      throw toApiError(
        error,
        "Error al crear el horario de atención",
        CREATE_OFFICE_HOUR_ERRORS,
      );
    }
  },

  async updateOfficeHour(
    id: string,
    payload: UpdateOfficeHourRequest
  ): Promise<OfficeHourDto> {
    try {
      const dayOfWeek =
        typeof payload.dayOfWeek === 'string' && payload.dayOfWeek in DAY_INDEX
          ? DAY_INDEX[payload.dayOfWeek as keyof typeof DAY_INDEX]
          : payload.dayOfWeek;

      const { data } = await httpClient.put<OfficeHourDto>(
        `/api/schedule/office-hours/${id}`,
        {
          ...payload,
          dayOfWeek,
        },
      );
      return data;
    } catch (error) {
      throw toApiError(
        error,
        "Error al actualizar el horario de atención",
        UPDATE_OFFICE_HOUR_ERRORS,
      );
    }
  },

  async deleteOfficeHour(id: string): Promise<void> {
    try {
      await httpClient.delete(`/api/schedule/office-hours/${id}`);
    } catch (error) {
      throw toApiError(
        error,
        "Error al eliminar el horario de atención",
        DELETE_OFFICE_HOUR_ERRORS,
      );
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

  async getStudentMeetings(
    studentId: string,
    from: string,
    to: string
  ): Promise<StudentMeetingsDto> {
    try {
      const { data } = await httpClient.get<StudentMeetingsDto>(
        `/api/schedule/students/${studentId}/meetings`,
        {
          params: {
            from: toScheduleDateTime(from),
            to: toScheduleDateTime(to),
          },
        }
      );
      return data;
    } catch (error) {
      throw toApiError(error, "Error al cargar las reuniones del estudiante");
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

  async rescheduleMeeting(
    id: string,
    payload: RescheduleMeetingRequest
  ): Promise<MeetingDto> {
    try {
      const { data } = await httpClient.put<MeetingDto>(
        `/api/schedule/meetings/${id}`,
        {
          ...payload,
          scheduledAt: toScheduleDateTime(payload.scheduledAt),
        }
      );
      return data;
    } catch (error) {
      throw toApiError(
        error,
        "Error al reagendar la reunión",
        RESCHEDULE_MEETING_ERRORS,
      );
    }
  },

  async cancelMeeting(id: string): Promise<void> {
    try {
      await httpClient.delete(`/api/schedule/meetings/${id}`);
    } catch (error) {
      throw toApiError(
        error,
        "Error al cancelar la reunión",
        CANCEL_MEETING_ERRORS,
      );
    }
  },
};
