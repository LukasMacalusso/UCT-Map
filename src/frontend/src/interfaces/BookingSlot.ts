export interface BookingSlot {
  key: string;
  start: Date;
  end: Date;
  structureRefId: string | null;
  isTaken: boolean;
}
