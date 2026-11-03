import React from 'react';
import { Select } from '../../components/ui/Select';
import { CampusMapCanvas, type CampusMapHandle } from '../../modules/map/CampusMapCanvas';
import { useBuildingLocations, useCampuses, useStructures } from '../../hooks/useCampus';
import { toBuildingMarker, toStructureMarker } from '../../modules/map/mapAdapters';
import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';
import { textPageColors } from '../../constants/colors';

import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';

interface EditorMapCanvasProps {
  children?: React.ReactNode;
  campusId?: string;
  showCampusSelector?: boolean;
  showControls?: boolean;
  topMessage?: React.ReactNode;
  selectedMarkerId?: string | null;
  onMapClick?: (coords: [number, number]) => void;
  onMarkerClick?: (marker: MapMarkerItem) => void;
  markersDraggable?: boolean;
  onMarkerDragEnd?: (marker: MapMarkerItem, coords: [number, number]) => void;
  cursorMode?: 'default' | 'crosshair' | 'grab' | 'pointer';
  onCampusChange?: (campusId: string) => void;
}

export const EditorMapCanvas = ({
  children,
  campusId,
  showCampusSelector = true,
  showControls = true,
  topMessage,
  selectedMarkerId,
  onMapClick,
  onMarkerClick,
  markersDraggable = false,
  onMarkerDragEnd,
  cursorMode = 'default',
  onCampusChange,
}: EditorMapCanvasProps) => {
  const [selectedCampus, setSelectedCampus] = React.useState('');
  const [internalSelectedMarker, setInternalSelectedMarker] = React.useState<MapMarkerItem | null>(null);

  const isControlled = selectedMarkerId !== undefined;
  const activeMarkerId = isControlled ? selectedMarkerId : internalSelectedMarker?.id ?? null;

  const mapRef = React.useRef<CampusMapHandle | null>(null);

  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const activeCampusId = campusId || selectedCampus || campuses?.[0]?.id || '';
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    activeCampusId || undefined,
    !areCampusesLoading,
  );
  const { data: structures, isLoading: areStructuresLoading } = useStructures(
    activeCampusId || undefined,
    !areCampusesLoading,
  );

  const markers: MapMarkerItem[] = React.useMemo(() => [
    ...(buildings ?? []).map(toBuildingMarker),
    ...(structures ?? []).map(toStructureMarker),
  ], [buildings, structures]);

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    onCampusChange?.(value);
    const campus = campuses?.find((item) => item.id === value);
    if (!campus) return;
    mapRef.current?.flyToCampus(campus);
  };

  const handleMarkerClick = React.useCallback(
    (marker: MapMarkerItem) => {
      if (!isControlled) {
        setInternalSelectedMarker(marker);
      }
      if (onMarkerClick) {
        onMarkerClick(marker);
      } else {
        mapRef.current?.flyToMarker(marker);
      }
    },
    [isControlled, onMarkerClick],
  );

  const handleMapClick = React.useCallback(
    (coords: [number, number]) => {
      if (!isControlled) {
        setInternalSelectedMarker(null);
      }
      onMapClick?.(coords);
    },
    [isControlled, onMapClick],
  );

  return (
    <CampusMapCanvas
      ref={mapRef}
      markers={markers}
      areMarkersLoading={areBuildingsLoading || areStructuresLoading}
      selectedMarkerId={activeMarkerId}
      onMarkerClick={handleMarkerClick}
      onMapClick={handleMapClick}
      markersDraggable={markersDraggable}
      onMarkerDragEnd={onMarkerDragEnd}
      cursorMode={cursorMode}
      showControls={showControls}
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
