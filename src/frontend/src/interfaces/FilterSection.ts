import type { FilterItem } from './FilterItem';

export interface FilterSection {
  id: string;
  title: string;
  items: FilterItem[];
}
