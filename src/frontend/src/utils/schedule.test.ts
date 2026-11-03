import { describe, it, expect } from 'vitest';
import {
  parseScheduleDate,
  timeToMinutes,
  formatTime,
  formatClock,
  formatLongDate,
  formatOfficeHour,
  sortOfficeHours,
  startOfDay,
  addDays,
  buildBookingDays,
  DAY_INDEX,
  DAY_LABELS,
} from './schedule';
import type { OfficeHourDto } from '../dtos/schedule/OfficeHourDto';
import type { MeetingDto } from '../dtos/schedule/MeetingDto';

describe('schedule utils', () => {
  it('has day index and labels correctly mapped', () => {
    expect(DAY_INDEX.Monday).toBe(1);
    expect(DAY_INDEX.Sunday).toBe(0);
    expect(DAY_LABELS[1]).toBe('Lunes');
  });

  it('parses schedule dates correctly with or without Z', () => {
    const withZ = parseScheduleDate('2026-11-03T10:00:00Z');
    expect(withZ.toISOString()).toBe('2026-11-03T10:00:00.000Z');

    const withoutZ = parseScheduleDate('2026-11-03T10:00:00');
    expect(withoutZ.toISOString()).toBe('2026-11-03T10:00:00.000Z');
  });

  it('converts time to minutes', () => {
    expect(timeToMinutes('08:30')).toBe(510);
    expect(timeToMinutes('00:00')).toBe(0);
  });

  it('formats time to 5 characters', () => {
    expect(formatTime('08:30:00')).toBe('08:30');
  });

  it('formats clock and long date', () => {
    const d = new Date('2026-11-03T14:30:00Z');
    expect(formatClock(d)).toBeDefined();
    expect(formatLongDate(d)).toBeDefined();
  });

  it('formats office hour block', () => {
    const block: OfficeHourDto = {
      id: '1',
      dayOfWeek: 'Monday',
      startTime: '09:00:00',
      endTime: '11:00:00',
      structureRefId: 'st-1',
    };
    expect(formatOfficeHour(block)).toBe('Lunes · 09:00 - 11:00');
  });

  it('sorts office hours by day and time', () => {
    const blocks: OfficeHourDto[] = [
      { id: '1', dayOfWeek: 'Friday', startTime: '10:00:00', endTime: '12:00:00', structureRefId: null },
      { id: '2', dayOfWeek: 'Monday', startTime: '14:00:00', endTime: '16:00:00', structureRefId: null },
      { id: '3', dayOfWeek: 'Monday', startTime: '09:00:00', endTime: '11:00:00', structureRefId: null },
    ];
    const sorted = sortOfficeHours(blocks);
    expect(sorted[0].id).toBe('3');
    expect(sorted[1].id).toBe('2');
    expect(sorted[2].id).toBe('1');
  });

  it('handles startOfDay and addDays', () => {
    const d = new Date('2026-11-03T15:30:00Z');
    const sod = startOfDay(d);
    expect(sod.getHours()).toBe(0);
    expect(sod.getMinutes()).toBe(0);

    const plus2 = addDays(sod, 2);
    expect(plus2.getDate()).toBe(sod.getDate() + 2);
  });

  describe('buildBookingDays', () => {
    it('generates booking slots for matching office hours', () => {
      // Mock Tuesday, 2026-11-03 at 08:00:00
      const now = new Date(2026, 10, 3, 8, 0, 0); // Month is 0-indexed: 10 = Nov
      const blocks: OfficeHourDto[] = [
        {
          id: 'b1',
          dayOfWeek: 'Tuesday',
          startTime: '09:00:00',
          endTime: '10:00:00',
          structureRefId: 'st-1',
        },
      ];
      const meetings: MeetingDto[] = [
        {
          id: 'm1',
          teacherRefId: 't1',
          studentRefId: 's1',
          scheduledAt: new Date(2026, 10, 3, 9, 0, 0).toISOString(),
          durationMinutes: 30,
          status: 'Confirmed',
          structureRefId: 'st-1',
        },
      ];

      const days = buildBookingDays(blocks, meetings, 30, 7, now);
      expect(days.length).toBeGreaterThan(0);
      const firstDay = days[0];
      expect(firstDay.slots.length).toBe(2);
      expect(firstDay.slots[0].isTaken).toBe(true);
      expect(firstDay.slots[1].isTaken).toBe(false);
      expect(firstDay.freeSlots).toBe(1);
    });

    it('ignores cancelled meetings and past slots', () => {
      const now = new Date(2026, 10, 3, 10, 0, 0);
      const blocks: OfficeHourDto[] = [
        {
          id: 'b1',
          dayOfWeek: 'Tuesday',
          startTime: '08:00:00',
          endTime: '11:00:00',
          structureRefId: 'st-1',
        },
      ];
      const meetings: MeetingDto[] = [
        {
          id: 'm1',
          teacherRefId: 't1',
          studentRefId: 's1',
          scheduledAt: new Date(2026, 10, 3, 10, 0, 0).toISOString(),
          durationMinutes: 30,
          status: 'Cancelled',
          structureRefId: 'st-1',
        },
      ];

      const days = buildBookingDays(blocks, meetings, 30, 1, now);
      expect(days.length).toBe(1);
      // Slot at 08:00, 08:30, 09:00, 09:30 are <= now, slot 10:00 is active and not taken because meeting is Cancelled
      expect(days[0].slots.some((s) => s.isTaken)).toBe(false);
    });
  });
});
