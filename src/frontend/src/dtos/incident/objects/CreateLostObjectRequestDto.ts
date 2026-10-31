import type { LostObjectStatus } from "../../../constants/lostObjectsStatus";

export interface CreateLostObjectRequestDto {
  title: string;
  description: string;
  status: LostObjectStatus;
  photoUrl?: string;
  structureId: string;
}
