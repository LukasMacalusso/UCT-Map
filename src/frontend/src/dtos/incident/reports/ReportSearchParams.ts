import type { ComplaintStatus } from "../../../constants/complaintStatus";
import type { TicketStatus } from "../../../constants/ticketStatus";

export interface ReportSearchParams {
  userRefId?: string;
  structureRefId?: string;
  type?: TicketStatus;
  isActive?: boolean;
  lostObjectId?: string;
  'complaintDetails.title'?: string;
  'complaintDetails.description'?: string;
  'complaintDetails.status'?: ComplaintStatus;
  sortBy?: 'ReportedAt' | 'Status';
  descending?: boolean;
  page?: number;
  pageSize?: number;
}
