import type { TicketStatus } from "../../constants/ticketStatus";
import type { ComplaintDetailsDto } from "./ComplaintDetailsDto";

export interface CreateReportRequestDto {
  structureRefId: string;
  ticketType: TicketStatus;
  isActive: boolean;
  reportedAt: string;
  lostObjectId?: string;
  complaint?: ComplaintDetailsDto;
}
