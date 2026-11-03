import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import { ActiveBuildingCard } from './ActiveBuildingCard';
import { ActiveStructureCard } from './ActiveStructureCard';

interface ActiveEntityCardProps {
  marker: MapMarkerItem | null;
  onClose: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const ActiveEntityCard = ({
  marker,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
  onReportLostObject,
}: ActiveEntityCardProps) => {
  if (!marker) return null;

  if (marker.type === 'building') {
    return (
      <ActiveBuildingCard
        building={marker.data as BuildingLocationDto}
        onClose={onClose}
        onNavigate={onNavigate}
        onView360={onView360}
        onReportProblem={onReportProblem}
        onReportLostObject={onReportLostObject}
      />
    );
  }

  return (
    <ActiveStructureCard
      structure={marker.data as StructureDto}
      onClose={onClose}
      onNavigate={onNavigate}
      onView360={onView360}
      onReportProblem={onReportProblem}
      onReportLostObject={onReportLostObject}
    />
  );
};
