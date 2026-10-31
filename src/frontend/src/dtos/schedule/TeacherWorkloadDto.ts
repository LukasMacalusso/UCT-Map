import type { MeetingDto } from "./MeetingDto";
import type { OfficeHourDto } from "./OfficeHourDto";

export interface TeacherWorkloadDto {
  TeacherRefId: string;
  From: string;
  To: string;
  WeeklyOfficeHourMinutes: number;
  TotalMeetings: number;
  OfficeHours: OfficeHourDto[];
  Meetings: MeetingDto[];
}
