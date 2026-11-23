import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';
import { resolveBuildingCoordinate, resolveStructureCoordinate } from './campusMapUtils';

export const toBuildingMarker = (building: BuildingLocationDto): MapMarkerItem<BuildingLocationDto> => ({
  id: building.id,
  name: building.name,
  type: 'building',
  coordinates: resolveBuildingCoordinate(building),
  color: 'blue',
  icon: <BuildingIcon className="w-5 h-5" />,
  data: building,
});

export const toStructureMarker = (structure: StructureDto): MapMarkerItem<StructureDto> => ({
  id: structure.id,
  name: structure.name,
  type: 'structure',
  coordinates: resolveStructureCoordinate(structure),
  color: 'yellow',
  icon: <CubeIcon className="w-5 h-5 text-gray-800" />,
  data: structure,
});
