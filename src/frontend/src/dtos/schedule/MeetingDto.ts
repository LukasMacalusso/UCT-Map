export type MeetingStatusName = 'Pending' | 'Confirmed' | 'Cancelled' | 'Completed';

export interface MeetingDto {
  id: string;
  teacherRefId: string;
  studentRefId: string;
  structureRefId: string | null;
  scheduledAt: string;
  durationMinutes: number;
  status: MeetingStatusName | string;
}
