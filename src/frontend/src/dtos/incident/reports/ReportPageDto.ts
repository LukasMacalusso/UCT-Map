import type { ReportDto } from "./ReportDto";

export interface ReportPageDto {
  items: ReportDto[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
