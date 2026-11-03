import type { DayOfWeekName } from './OfficeHourDto';

export interface CreateOfficeHourRequest {
  teacherRefId: string;
  structureRefId: string | null;
  dayOfWeek: DayOfWeekName | number;
  startTime: string;
  endTime: string;
}
