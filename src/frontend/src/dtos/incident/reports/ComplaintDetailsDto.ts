import type { ComplaintStatus } from "../../../constants/complaintStatus";

export interface ComplaintDetailsDto {
  title: string;
  description: string;
  status: ComplaintStatus;
}
