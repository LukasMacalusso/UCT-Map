import type { BookingSlot } from './BookingSlot';

export interface BookingDay {
  key: string;
  date: Date;
  slots: BookingSlot[];
  freeSlots: number;
}
