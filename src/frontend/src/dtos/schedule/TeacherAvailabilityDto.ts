import type { OfficeHourDto } from "./OfficeHourDto";

export interface TeacherAvailabilityDto {
  TeacherRefId: string;
  AvailableBlocks: OfficeHourDto[];
}
