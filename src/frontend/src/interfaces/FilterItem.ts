import { type ReactNode } from 'react';

export interface FilterItem {
  id: string;
  label: string;
  icon?: ReactNode;
  checked?: boolean;
}
