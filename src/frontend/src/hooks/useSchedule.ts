import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { queryKeys } from '../api/queryKeys';
import { scheduleService } from '../services/scheduleService';
import type { CreateMeetingRequest } from '../dtos/schedule/CreateMeetingRequest';
import type { MeetingDto } from '../dtos/schedule/MeetingDto';
import type { OfficeHourDto } from '../dtos/schedule/OfficeHourDto';
import type { TeacherAvailabilityDto } from '../dtos/schedule/TeacherAvailabilityDto';
import type { TeacherWorkloadDto } from '../dtos/schedule/TeacherWorkloadDto';

export const useOfficeHours = (teacherId?: string, enabled = true) => {
  return useQuery<OfficeHourDto[], Error>({
    queryKey: queryKeys.teachers.officeHours(teacherId),
    queryFn: () => scheduleService.getOfficeHours(teacherId),
    enabled,
  });
};

export const useTeacherAvailability = (teacherId?: string) => {
  return useQuery<TeacherAvailabilityDto, Error>({
    queryKey: queryKeys.teachers.availability(teacherId ?? ''),
    queryFn: () => scheduleService.getAvailability(teacherId!),
    enabled: !!teacherId,
  });
};

export const useTeacherWorkload = (teacherId?: string, from?: string, to?: string) => {
  return useQuery<TeacherWorkloadDto, Error>({
    queryKey: queryKeys.teachers.workload(teacherId ?? '', from ?? '', to ?? ''),
    queryFn: () => scheduleService.getWorkload(teacherId!, from!, to!),
    enabled: !!teacherId && !!from && !!to,
  });
};

export const useTeacherMeetings = (teacherId?: string, from?: string, to?: string) => {
  return useQuery<MeetingDto[], Error>({
    queryKey: queryKeys.teachers.meetings(teacherId, from, to),
    queryFn: () => scheduleService.getMeetings(teacherId, from, to),
    enabled: !!teacherId && !!from && !!to,
  });
};

export const useAllMeetings = (enabled = true) => {
  return useQuery<MeetingDto[], Error>({
    queryKey: queryKeys.teachers.meetings(),
    queryFn: () => scheduleService.getMeetings(),
    enabled,
  });
};

export const useCreateMeeting = () => {
  const queryClient = useQueryClient();

  return useMutation<MeetingDto, Error, CreateMeetingRequest>({
    mutationFn: (payload) => scheduleService.createMeeting(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.teachers.all });
    },
  });
};
