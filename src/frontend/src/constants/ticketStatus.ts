export const TicketStatus = {
  Pending: 0,
  InProcess: 1,
  Resolved: 2,
  Dismissed: 3,
} as const;
export type TicketStatus = (typeof TicketStatus)[keyof typeof TicketStatus];

export const TICKET_STATUS_LABELS: Record<TicketStatus, string> = {
  [TicketStatus.Pending]: 'SIN REVISAR',
  [TicketStatus.InProcess]: 'EN PROCESO',
  [TicketStatus.Resolved]: 'RESUELTO',
  [TicketStatus.Dismissed]: 'DESCARTADO',
};

export const TICKET_STATUS_COLORS: Record<
  TicketStatus,
  'blue' | 'green' | 'yellow' | 'red' | 'gray' | 'white'
> = {
  [TicketStatus.Pending]: 'red',
  [TicketStatus.InProcess]: 'yellow',
  [TicketStatus.Resolved]: 'green',
  [TicketStatus.Dismissed]: 'gray',
};
