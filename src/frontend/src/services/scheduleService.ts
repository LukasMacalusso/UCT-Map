import { toApiError } from "../api/apiError";
import httpClient from "../api/httpClient";
import type { CreateMeetingRequest } from "../dtos/schedule/CreateMeetingRequest";
import type { MeetingDto } from "../dtos/schedule/MeetingDto";
import type { TeacherAvailabilityDto } from "../dtos/schedule/TeacherAvailabilityDto";
import type { TeacherWorkloadDto } from "../dtos/schedule/TeacherWorkloadDto";

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

  async createMeeting(payload: CreateMeetingRequest): Promise<string> {
    try {
      const { data } = await httpClient.post<{ id: string }>(
        "/api/schedule/meetings",
        payload
      );
      return data.id;
    } catch (error) {
      throw toApiError(error, "Error al crear la reunión");
    }
  },
};
