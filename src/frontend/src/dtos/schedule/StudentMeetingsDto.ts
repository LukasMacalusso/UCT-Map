import type { MeetingDto } from './MeetingDto';

export interface StudentMeetingsDto {
  studentRefId: string;
  from: string;
  to: string;
  meetingCount: number;
  meetings: MeetingDto[];
}
