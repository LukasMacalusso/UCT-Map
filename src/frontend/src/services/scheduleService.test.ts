import { describe, it, expect, vi, beforeEach } from 'vitest';
import { scheduleService } from './scheduleService';
import httpClient from '../api/httpClient';
import type { CreateOfficeHourRequest } from '../dtos/schedule/CreateOfficeHourRequest';

vi.mock('../api/httpClient');

describe('scheduleService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getAvailability calls GET', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: { teacherId: 't1', isAvailable: true } });
    const res = await scheduleService.getAvailability('t1');
    expect(res.isAvailable).toBe(true);
  });

  it('getWorkload calls GET with formatted dates', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: { teacherId: 't1', weeklyHours: 20 } });
    const res = await scheduleService.getWorkload('t1', '2026-11-03T10:00:00Z', '2026-11-03T18:00:00Z');
    expect(res.weeklyHours).toBe(20);
    expect(httpClient.get).toHaveBeenCalledWith('/api/schedule/teachers/t1/workload', {
      params: { from: '2026-11-03T10:00:00', to: '2026-11-03T18:00:00' },
    });
  });

  it('getOfficeHours calls GET with teacherId', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [] });
    const res = await scheduleService.getOfficeHours('t1');
    expect(res).toEqual([]);
    expect(httpClient.get).toHaveBeenCalledWith('/api/schedule/office-hours', {
      params: { teacherId: 't1' },
    });
  });

  it('createOfficeHour calls POST with the payload', async () => {
    const payload: CreateOfficeHourRequest = {
      teacherRefId: 't1',
      structureRefId: 'st1',
      dayOfWeek: 'Monday',
      startTime: '09:00:00',
      endTime: '10:00:00',
    };
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'oh1' } });

    const res = await scheduleService.createOfficeHour(payload);

    expect(res.id).toBe('oh1');
    expect(httpClient.post).toHaveBeenCalledWith('/api/schedule/office-hours', {
      ...payload,
      dayOfWeek: 1,
    });
  });

  it('createOfficeHour maps a bad request error', async () => {
    const payload: CreateOfficeHourRequest = {
      teacherRefId: 't1',
      structureRefId: null,
      dayOfWeek: 'Monday',
      startTime: '09:00:00',
      endTime: '08:00:00',
    };
    vi.mocked(httpClient.post).mockRejectedValueOnce({
      isAxiosError: true,
      response: { status: 400, data: {} },
    });

    await expect(scheduleService.createOfficeHour(payload)).rejects.toThrow(
      'Los datos del horario no son válidos',
    );
  });

  it('getMeetings calls GET', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [] });
    await scheduleService.getMeetings('t1', '2026-11-03T00:00:00Z');
    expect(httpClient.get).toHaveBeenCalledWith('/api/schedule/meetings', {
      params: { teacherId: 't1', from: '2026-11-03T00:00:00', to: undefined },
    });
  });

  it('createMeeting calls POST with formatted scheduledAt', async () => {
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'm1' } });
    const res = await scheduleService.createMeeting({
      teacherRefId: 't1',
      studentRefId: 's1',
      scheduledAt: '2026-11-03T10:00:00Z',
      durationMinutes: 30,
    });
    expect(res.id).toBe('m1');
    expect(httpClient.post).toHaveBeenCalledWith('/api/schedule/meetings', {
      teacherRefId: 't1',
      studentRefId: 's1',
      scheduledAt: '2026-11-03T10:00:00',
      durationMinutes: 30,
    });
  });

  it('updateMeetingStatus calls PATCH', async () => {
    vi.mocked(httpClient.patch).mockResolvedValueOnce({ data: { id: 'm1', status: 'Confirmed' } });
    const res = await scheduleService.updateMeetingStatus('m1', 'Confirmed');
    expect(res.status).toBe('Confirmed');
    expect(httpClient.patch).toHaveBeenCalledWith('/api/schedule/meetings/m1/status', {
      status: 'Confirmed',
    });
  });
});
