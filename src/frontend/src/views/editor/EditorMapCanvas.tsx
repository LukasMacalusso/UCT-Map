import React from 'react';
import { Select } from '../../components/ui/Select';
import { CampusMapCanvas, type CampusMapHandle } from '../../modules/map/CampusMapCanvas';
import { useBuildingLocations, useCampuses } from '../../hooks/useCampus';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import { textPageColors } from '../../constants/colors';

import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';

interface EditorMapCanvasProps {
  children?: React.ReactNode;
  campusId?: string;
  showCampusSelector?: boolean;
  topMessage?: React.ReactNode;
  selectedBuildingId?: string | null;
  onMapClick?: (coords: [number, number]) => void;
  onBuildingClick?: (building: BuildingLocationDto) => void;
  markersDraggable?: boolean;
  onMarkerDragEnd?: (building: BuildingLocationDto, coords: [number, number]) => void;
  cursorMode?: 'default' | 'crosshair' | 'grab' | 'pointer';
  onCampusChange?: (campusId: string) => void;
}

export const EditorMapCanvas = ({
  children,
  campusId,
  showCampusSelector = true,
  topMessage,
  selectedBuildingId,
  onMapClick,
  onBuildingClick,
  markersDraggable = false,
  onMarkerDragEnd,
  cursorMode = 'default',
  onCampusChange,
}: EditorMapCanvasProps) => {
  const [selectedCampus, setSelectedCampus] = React.useState('');
  const [selectedBuilding, setSelectedBuilding] = React.useState<BuildingLocationDto | null>(null);

  const isControlled = selectedBuildingId !== undefined;
  const activeBuildingId = isControlled
    ? selectedBuildingId
    : selectedBuilding?.id ?? null;

  const mapRef = React.useRef<CampusMapHandle | null>(null);

  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const activeCampusId = campusId || selectedCampus || campuses?.[0]?.id || '';
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    activeCampusId || undefined,
    !areCampusesLoading,
  );

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    onCampusChange?.(value);
    const campus = campuses?.find((item) => item.id === value);
    if (!campus) return;
    mapRef.current?.flyToCampus(campus);
  };

  const handleBuildingClick = React.useCallback(
    (building: BuildingLocationDto) => {
      if (!isControlled) {
        setSelectedBuilding(building);
      }
      if (onBuildingClick) {
        onBuildingClick(building);
      } else {
        mapRef.current?.flyToBuilding(building);
      }
    },
    [isControlled, onBuildingClick],
  );

  const handleMapClick = React.useCallback(
    (coords: [number, number]) => {
      if (!isControlled) {
        setSelectedBuilding(null);
      }
      onMapClick?.(coords);
    },
    [isControlled, onMapClick],
  );

  return (
    <CampusMapCanvas
      ref={mapRef}
      buildings={buildings}
      areBuildingsLoading={areBuildingsLoading}
      selectedBuildingId={activeBuildingId}
      onBuildingClick={handleBuildingClick}
      onMapClick={handleMapClick}
      markersDraggable={markersDraggable}
      onMarkerDragEnd={onMarkerDragEnd}
      cursorMode={cursorMode}
    >
      {/* Centered Top Action Message (vertically aligned with Campus Select button) */}
      {topMessage && (
        <div className="absolute top-6 left-0 right-0 z-30 flex items-end justify-center pointer-events-none">
          {topMessage}
        </div>
      )}

      {/* Right: Campus Selector */}
      {showCampusSelector && (
        <div className="absolute top-6 right-6 z-20 w-full max-w-xs pointer-events-auto">
          <Select
            label="Campus"
            labelColor={textPageColors.dark}
            options={(campuses ?? []).map((campus) => ({
              value: campus.id,
              label: campus.name,
            }))}
            value={activeCampusId}
            onChange={handleCampusChange}
            icon={<BuildingIcon className="w-6 h-6 text-gray-700" />}
          />
        </div>
      )}

      {children}
    </CampusMapCanvas>
  );
};
