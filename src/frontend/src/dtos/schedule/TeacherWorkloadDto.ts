import type { MeetingDto } from "./MeetingDto";
import type { OfficeHourDto } from "./OfficeHourDto";

export interface TeacherWorkloadDto {
  teacherRefId: string;
  from: string;
  to: string;
  weeklyOfficeHourMinutes: number;
  totalMeetings: number;
  officeHours: OfficeHourDto[];
  meetings: MeetingDto[];
}
