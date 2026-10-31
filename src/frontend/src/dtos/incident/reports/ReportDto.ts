import type { TicketStatus } from "../../../constants/ticketStatus";
import type { ComplaintDetailsDto } from "./ComplaintDetailsDto";

export interface ReportDto {
  id: string;
  userRefId: string;
  structureRefId: string | null;
  ticketType: TicketStatus;
  isActive: boolean;
  reportedAt: string;
  complaintDetails: ComplaintDetailsDto | null;
  lostObjectId: string | null;
}
