import type { OfficeHourDto } from "./OfficeHourDto";

export interface TeacherAvailabilityDto {
  teacherRefId: string;
  availableBlocks: OfficeHourDto[];
}
