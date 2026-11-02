export interface CreateMeetingRequest {
  teacherRefId: string;
  studentRefId: string;
  structureRefId: string | null;
  scheduledAt: string;
  durationMinutes: number;
}
