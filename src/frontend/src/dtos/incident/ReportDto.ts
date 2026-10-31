import type { ComplaintStatus } from "../../constants/complaintStatus";
import type { TicketStatus } from "../../constants/ticketStatus";

export interface ReportDto {
  id: string;
  userRefId: string;
  structureRefId: string | null;
  ticketType: TicketStatus;
  isActive: boolean;
  reportedAt: string;
  complaintDetails: ComplaintStatus | null;
  lostObjectId: string | null;
}
