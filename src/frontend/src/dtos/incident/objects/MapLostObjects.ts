import { parseLostObjectStatus } from "../../../constants/lostObjectsStatus";
import type { LostObjectApiDto } from "./LostObjectApiDto";
import type { LostObjectDto } from "./LostObjectDto";

export const mapLostObject = (dto: LostObjectApiDto): LostObjectDto => ({
  title: dto.title,
  description: dto.description,
  reportedAt: dto.date,
  status: parseLostObjectStatus(dto.status),
  photoUrl: dto.photoUrl ?? undefined,
  structureId: dto.structureId,
});
