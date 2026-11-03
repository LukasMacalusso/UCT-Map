import type React from 'react';
import type { PageColor } from '../constants/colors';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../dtos/campus/StructureDto';

export type MapEntityType = 'building' | 'structure';

export interface MapMarkerItem<T = BuildingLocationDto | StructureDto> {
  id: string;
  name: string;
  type: MapEntityType;
  coordinates: [number, number]; // [lng, lat]
  color?: PageColor;
  icon?: React.ReactNode;
  data: T;
}
