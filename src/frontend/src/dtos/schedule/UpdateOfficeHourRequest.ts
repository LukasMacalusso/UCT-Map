import type { DayOfWeekName } from './OfficeHourDto';

export interface UpdateOfficeHourRequest {
  structureRefId: string | null;
  dayOfWeek: DayOfWeekName | number;
  startTime: string;
  endTime: string;
}
