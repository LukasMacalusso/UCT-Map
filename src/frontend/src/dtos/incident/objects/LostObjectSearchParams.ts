import type { LostObjectStatus } from "../../../constants/lostObjectsStatus";

export interface LostObjectSearchParams {
  title?: string;
  structureId?: string;
  status?: LostObjectStatus;
  sortBy?: 'ReportedAt' | 'Title' | 'Status';
  descending?: boolean;
  page?: number;
  pageSize?: number;
}
