import type { DayOfWeekName, OfficeHourDto } from '../dtos/schedule/OfficeHourDto';
import type { MeetingDto } from '../dtos/schedule/MeetingDto';

export const DAY_INDEX: Record<DayOfWeekName, number> = {
  Sunday: 0,
  Monday: 1,
  Tuesday: 2,
  Wednesday: 3,
  Thursday: 4,
  Friday: 5,
  Saturday: 6,
};

export const DAY_LABELS = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

export const MEETING_STATUS_LABELS: Record<string, string> = {
  Pending: 'PENDIENTE',
  Confirmed: 'CONFIRMADA',
  Cancelled: 'CANCELADA',
  Completed: 'COMPLETADA',
};

export const MEETING_STATUS_COLORS: Record<string, 'yellow' | 'blue' | 'red' | 'green'> = {
  Pending: 'yellow',
  Confirmed: 'blue',
  Cancelled: 'red',
  Completed: 'green',
};

export const DURATION_OPTIONS = [15, 30, 45, 60];

export interface BookingSlot {
  key: string;
  start: Date;
  end: Date;
  structureRefId: string | null;
  isTaken: boolean;
}

export interface BookingDay {
  key: string;
  date: Date;
  slots: BookingSlot[];
  freeSlots: number;
}

const TIMEZONE_SUFFIX = /(Z|[+-]\d{2}:?\d{2})$/i;

export const parseScheduleDate = (value: string): Date => {
  const normalized = TIMEZONE_SUFFIX.test(value) ? value : `${value}Z`;
  return new Date(normalized);
};

export const timeToMinutes = (value: string): number => {
  const [hours = '0', minutes = '0'] = value.split(':');
  return Number(hours) * 60 + Number(minutes);
};

export const formatTime = (value: string): string => value.slice(0, 5);

export const formatClock = (date: Date): string =>
  date.toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit', hour12: false });

export const formatLongDate = (date: Date): string => {
  const label = date.toLocaleDateString('es-CL', { weekday: 'long', day: 'numeric', month: 'long' });
  return label.charAt(0).toUpperCase() + label.slice(1);
};

export const formatOfficeHour = (block: OfficeHourDto): string =>
  `${DAY_LABELS[DAY_INDEX[block.dayOfWeek]] ?? block.dayOfWeek} · ${formatTime(block.startTime)} - ${formatTime(block.endTime)}`;

export const sortOfficeHours = (blocks: OfficeHourDto[]): OfficeHourDto[] =>
  [...blocks].sort((a, b) => {
    const dayA = (DAY_INDEX[a.dayOfWeek] + 6) % 7;
    const dayB = (DAY_INDEX[b.dayOfWeek] + 6) % 7;
    return dayA - dayB || timeToMinutes(a.startTime) - timeToMinutes(b.startTime);
  });

export const startOfDay = (date: Date): Date => {
  const copy = new Date(date);
  copy.setHours(0, 0, 0, 0);
  return copy;
};

export const addDays = (date: Date, days: number): Date => {
  const copy = new Date(date);
  copy.setDate(copy.getDate() + days);
  return copy;
};

const toDayKey = (date: Date): string =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

export const buildBookingDays = (
  blocks: OfficeHourDto[],
  meetings: MeetingDto[],
  durationMinutes: number,
  daysAhead: number,
  now: Date = new Date(),
): BookingDay[] => {
  const busy = meetings
    .filter((meeting) => meeting.status !== 'Cancelled')
    .map((meeting) => {
      const start = parseScheduleDate(meeting.scheduledAt).getTime();
      return { start, end: start + meeting.durationMinutes * 60000 };
    });

  const today = startOfDay(now);
  const days: BookingDay[] = [];

  for (let offset = 0; offset < daysAhead; offset += 1) {
    const date = addDays(today, offset);
    const dayBlocks = blocks.filter((block) => DAY_INDEX[block.dayOfWeek] === date.getDay());

    if (dayBlocks.length === 0) continue;

    const slots: BookingSlot[] = [];

    sortOfficeHours(dayBlocks).forEach((block) => {
      const blockEnd = timeToMinutes(block.endTime);

      for (
        let minute = timeToMinutes(block.startTime);
        minute + durationMinutes <= blockEnd;
        minute += durationMinutes
      ) {
        const start = new Date(date);
        start.setHours(Math.floor(minute / 60), minute % 60, 0, 0);

        if (start.getTime() <= now.getTime()) continue;

        const end = new Date(start.getTime() + durationMinutes * 60000);
        const isTaken = busy.some(
          (meeting) => meeting.start < end.getTime() && start.getTime() < meeting.end,
        );

        slots.push({
          key: `${block.id}-${start.toISOString()}`,
          start,
          end,
          structureRefId: block.structureRefId,
          isTaken,
        });
      }
    });

    if (slots.length === 0) continue;

    days.push({
      key: toDayKey(date),
      date,
      slots,
      freeSlots: slots.filter((slot) => !slot.isTaken).length,
    });
  }

  return days;
};
