import type { LostObjectDto } from './LostObjectDto';

export interface LostObjectPageDto {
  items: LostObjectDto[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
