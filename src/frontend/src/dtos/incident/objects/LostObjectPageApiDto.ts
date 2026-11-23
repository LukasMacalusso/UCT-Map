import type { LostObjectApiDto } from "./LostObjectApiDto";

export interface LostObjectPageApiDto {
  items: LostObjectApiDto[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
