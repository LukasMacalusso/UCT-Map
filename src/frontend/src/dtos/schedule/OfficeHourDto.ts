export type DayOfWeekName =
  | 'Sunday'
  | 'Monday'
  | 'Tuesday'
  | 'Wednesday'
  | 'Thursday'
  | 'Friday'
  | 'Saturday';

export interface OfficeHourDto {
  id: string;
  teacherRefId: string;
  structureRefId: string | null;
  dayOfWeek: DayOfWeekName;
  startTime: string;
  endTime: string;
}
