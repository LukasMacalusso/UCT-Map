export const LostObjectStatus = {
  Pending: 0,
  InProcess: 1,
  Resolved: 2,
  Canceled: 3,
} as const;
export type LostObjectStatus = (typeof LostObjectStatus)[keyof typeof LostObjectStatus];

const LOST_OBJECT_STATUS_NAMES: Record<string, LostObjectStatus> = {
  Pending: LostObjectStatus.Pending,
  In_Process: LostObjectStatus.InProcess,
  Resolved: LostObjectStatus.Resolved,
  Canceled: LostObjectStatus.Canceled,
};

export const parseLostObjectStatus = (value: string | number): LostObjectStatus => {
  if (typeof value === 'number') return value as LostObjectStatus;
  return LOST_OBJECT_STATUS_NAMES[value] ?? LostObjectStatus.Pending;
};

export const LOST_OBJECT_STATUS_LABELS: Record<LostObjectStatus, string> = {
  [LostObjectStatus.Pending]: 'PENDIENTE',
  [LostObjectStatus.InProcess]: 'EN PROCESO',
  [LostObjectStatus.Resolved]: 'RESUELTO',
  [LostObjectStatus.Canceled]: 'CANCELADO',
};

export const LOST_OBJECT_STATUS_COLORS: Record<
  LostObjectStatus,
  'blue' | 'green' | 'yellow' | 'red' | 'gray' | 'white'
> = {
  [LostObjectStatus.Pending]: 'blue',
  [LostObjectStatus.InProcess]: 'yellow',
  [LostObjectStatus.Resolved]: 'green',
  [LostObjectStatus.Canceled]: 'gray',
};
