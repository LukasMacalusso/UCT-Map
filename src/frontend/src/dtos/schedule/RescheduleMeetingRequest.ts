export interface RescheduleMeetingRequest {
  structureRefId: string | null;
  scheduledAt: string;
  durationMinutes: number;
}
