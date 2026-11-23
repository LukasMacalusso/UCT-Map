import type { LostObjectStatus } from "../../../constants/lostObjectsStatus";

export interface LostObjectDto {
  id?: string;
  lostObjectId?: string;
  userRefId?: string;
  title: string;
  description: string;
  reportedAt: string;
  status: LostObjectStatus;
  photoUrl?: string;
  structureId: string;
}
