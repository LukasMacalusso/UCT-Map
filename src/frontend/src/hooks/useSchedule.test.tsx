import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  useOfficeHours,
  useTeacherAvailability,
  useTeacherWorkload,
  useTeacherMeetings,
  useAllMeetings,
  useCreateMeeting,
  useCreateOfficeHour,
  useUpdateMeetingStatus,
} from './useSchedule';
import { scheduleService } from '../services/scheduleService';
import type { TeacherAvailabilityDto } from '../dtos/schedule/TeacherAvailabilityDto';
import type { TeacherWorkloadDto } from '../dtos/schedule/TeacherWorkloadDto';
import type { MeetingDto } from '../dtos/schedule/MeetingDto';
import type { OfficeHourDto } from '../dtos/schedule/OfficeHourDto';

vi.mock('../services/scheduleService');

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useSchedule hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('queries schedule data', async () => {
    vi.mocked(scheduleService.getOfficeHours).mockResolvedValue([]);
    vi.mocked(scheduleService.getAvailability).mockResolvedValue({ teacherId: 't1', isAvailable: true } as unknown as TeacherAvailabilityDto);
    vi.mocked(scheduleService.getWorkload).mockResolvedValue({ teacherId: 't1' } as unknown as TeacherWorkloadDto);
    vi.mocked(scheduleService.getMeetings).mockResolvedValue([]);

    const wrapper = createWrapper();
    const { result: oh } = renderHook(() => useOfficeHours('t1'), { wrapper });
    await waitFor(() => expect(oh.current.isSuccess).toBe(true));

    const { result: ta } = renderHook(() => useTeacherAvailability('t1'), { wrapper });
    await waitFor(() => expect(ta.current.isSuccess).toBe(true));

    const { result: wl } = renderHook(() => useTeacherWorkload('t1', 'from', 'to'), { wrapper });
    await waitFor(() => expect(wl.current.isSuccess).toBe(true));

    const { result: tm } = renderHook(() => useTeacherMeetings('t1', 'from', 'to'), { wrapper });
    await waitFor(() => expect(tm.current.isSuccess).toBe(true));

    const { result: am } = renderHook(() => useAllMeetings(), { wrapper });
    await waitFor(() => expect(am.current.isSuccess).toBe(true));
  });

  it('creates an office hour', async () => {
    vi.mocked(scheduleService.createOfficeHour).mockResolvedValue({
      id: 'oh1',
    } as unknown as OfficeHourDto);

    const wrapper = createWrapper();
    const { result } = renderHook(() => useCreateOfficeHour(), { wrapper });

    await act(async () => {
      await result.current.mutateAsync({
        teacherRefId: 't1',
        structureRefId: null,
        dayOfWeek: 'Monday',
        startTime: '09:00:00',
        endTime: '10:00:00',
      });
    });

    expect(scheduleService.createOfficeHour).toHaveBeenCalledWith({
      teacherRefId: 't1',
      structureRefId: null,
      dayOfWeek: 'Monday',
      startTime: '09:00:00',
      endTime: '10:00:00',
    });
  });

  it('mutations create and update meeting status', async () => {
    vi.mocked(scheduleService.createMeeting).mockResolvedValue({ id: 'm1' } as unknown as MeetingDto);
    vi.mocked(scheduleService.updateMeetingStatus).mockResolvedValue({ id: 'm1', status: 'Confirmed' } as unknown as MeetingDto);

    const wrapper = createWrapper();
    const { result: cm } = renderHook(() => useCreateMeeting(), { wrapper });
    await act(async () => {
      await cm.current.mutateAsync({ teacherRefId: 't1', studentRefId: 's1', scheduledAt: '2026-11-03', durationMinutes: 30 });
    });
    expect(scheduleService.createMeeting).toHaveBeenCalled();

    const { result: um } = renderHook(() => useUpdateMeetingStatus(), { wrapper });
    await act(async () => {
      await um.current.mutateAsync({ id: 'm1', status: 'Confirmed' });
    });
    expect(scheduleService.updateMeetingStatus).toHaveBeenCalledWith('m1', 'Confirmed');
  });
});
