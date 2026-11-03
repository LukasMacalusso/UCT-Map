import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { SquareButton } from '../components/ui/SquareButton';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import { RoleGuard } from '../router/RoleGuard';
import { MapSidePanel } from '../modules/map/MapSidePanel';
import { MapHeatmapPanel, type HeatmapMode } from '../modules/map/MapHeatmapPanel';
import { useBuildingLocations, useCampuses, useStructures } from '../hooks/useCampus';
import { useReports } from '../hooks/useReports';
import { useLostObjects } from '../hooks/useLostObjects';
import { ActiveEntityCard } from '../modules/map/ActiveEntityCard';
import { CampusMapCanvas, type CampusMapHandle } from '../modules/map/CampusMapCanvas';
import { toBuildingMarker, toStructureMarker } from '../modules/map/mapAdapters';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../dtos/campus/StructureDto';
import type { MapMarkerItem } from '../interfaces/MapMarkerItem';
import { textPageColors } from '../constants/colors';
import { OFFICIAL_ROLES } from '../constants/role';

export const MapView = () => {
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isSidePanelOpen, setIsSidePanelOpen] = React.useState(false);
  const [selectedMarker, setSelectedMarker] = React.useState<MapMarkerItem | null>(null);
  const [isDetailCardOpen, setIsDetailCardOpen] = React.useState(false);
  const [selectedCampus, setSelectedCampus] = React.useState('');
  const [heatmapMode, setHeatmapMode] = React.useState<HeatmapMode>('none');

  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const activeCampusId = selectedCampus || campuses?.[0]?.id || '';
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    activeCampusId || undefined,
    !areCampusesLoading
  );
  const { data: structures, isLoading: areStructuresLoading } = useStructures(
    activeCampusId || undefined,
    !areCampusesLoading
  );

  // Queries for heatmap
  const { data: reportsData } = useReports(
    { pageSize: 100 },
    heatmapMode === 'reports'
  );
  const { data: lostObjectsData } = useLostObjects(
    { pageSize: 100 },
    heatmapMode === 'objects'
  );

  // Counts mapped by structure/building ID
  const countsByEntityId = React.useMemo(() => {
    const map = new Map<string, number>();
    if (heatmapMode === 'reports') {
      (reportsData?.items ?? []).forEach((r) => {
        if (r.structureRefId) {
          map.set(r.structureRefId, (map.get(r.structureRefId) ?? 0) + 1);
        }
      });
    } else if (heatmapMode === 'objects') {
      (lostObjectsData?.items ?? []).forEach((o) => {
        if (o.structureId) {
          map.set(o.structureId, (map.get(o.structureId) ?? 0) + 1);
        }
      });
    }
    return map;
  }, [heatmapMode, reportsData?.items, lostObjectsData?.items]);

  const markers: MapMarkerItem[] = React.useMemo(() => {
    const base = [
      ...(buildings ?? []).map(toBuildingMarker),
      ...(structures ?? []).map(toStructureMarker),
    ];

    if (heatmapMode === 'none') return base;

    return base.map((m) => {
      const count = countsByEntityId.get(m.id) ?? 0;
      // Escala absoluta fija: 1 objeto/reporte = ~15% (naranja suave y radio pequeño), y crece hasta 7+ = 100% (rojo grande)
      const intensity = count > 0 ? Math.min(Math.round((count / 7) * 100), 100) : 0;
      return {
        ...m,
        badge: count > 0 ? count : undefined,
        heatmapIntensity: intensity,
      };
    });
  }, [buildings, structures, heatmapMode, countsByEntityId]);

  const mapRef = React.useRef<CampusMapHandle | null>(null);
  const cardCloseTimeoutRef = React.useRef<number | null>(null);
  const navigate = useNavigate();

  const mapSearchOptions = markers.map((m) => ({
    value: m.id,
    label: `${m.name} (${m.type === 'building' ? 'Edificio' : 'Estructura'})`,
  }));

  const handleMarkerClick = React.useCallback((marker: MapMarkerItem) => {
    if (cardCloseTimeoutRef.current) {
      window.clearTimeout(cardCloseTimeoutRef.current);
      cardCloseTimeoutRef.current = null;
    }
    setSelectedMarker(marker);
    setIsDetailCardOpen(true);
    mapRef.current?.flyToMarker(marker);
  }, []);

  const handleCloseDetailCard = React.useCallback(() => {
    setIsDetailCardOpen(false);
    cardCloseTimeoutRef.current = window.setTimeout(() => {
      setSelectedMarker(null);
      cardCloseTimeoutRef.current = null;
    }, 500);
  }, []);

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    handleCloseDetailCard();
    const campus = campuses?.find((item) => item.id === value);
    if (!campus) return;
    mapRef.current?.flyToCampus(campus);
  };

  return (
    <CampusMapCanvas
      ref={mapRef}
      markers={markers}
      areMarkersLoading={areBuildingsLoading || areStructuresLoading}
      selectedMarkerId={selectedMarker?.id ?? null}
      onMarkerClick={handleMarkerClick}
    >
      <div className="absolute top-6 right-6 left-6 sm:left-auto z-10 flex flex-row gap-3 items-end">
        <div className="w-full min-w-0 sm:w-72 lg:w-80">
          <SearchInput
            label="Búsqueda"
            labelColor={textPageColors.dark}
            placeholder="Buscar edificio o estructura..."
            value={searchQuery}
            onChange={(val) => setSearchQuery(val)}
            icon={<SearchIcon className="w-6 h-6 text-gray-500" />}
            options={mapSearchOptions}
            onSelectOption={(option) => {
              const marker = markers.find((m) => m.id === option.value);
              if (marker) handleMarkerClick(marker);
            }}
          />
        </div>

        <div className="w-full min-w-0 sm:w-72 lg:w-80">
          <Select
            label="Campus"
            labelColor={textPageColors.dark}
            options={(campuses ?? []).map((campus) => ({ value: campus.id, label: campus.name }))}
            value={activeCampusId}
            onChange={handleCampusChange}
            icon={<BuildingIcon className="w-6 h-6 text-gray-700" />}
          />
        </div>

        <SquareButton
          onClick={() => setIsSidePanelOpen(!isSidePanelOpen)}
          title={isSidePanelOpen ? 'Cerrar panel' : 'Abrir panel'}
          className={isSidePanelOpen ? '!bg-page-blue !text-white' : ''}
        >
          <FilterIcon className="w-7 h-7" />
        </SquareButton>
      </div>

      {/* Side Panel */}
      <div
        className={`absolute top-28 bottom-24 right-6 z-40 w-[28.25rem] flex flex-col gap-3 transition-transform duration-500 ${
          isSidePanelOpen ? 'translate-x-0' : 'translate-x-[150%]'
        }`}
      >
        <div className="flex-1 min-h-0">
          <MapSidePanel onClose={() => setIsSidePanelOpen(false)} />
        </div>
        <RoleGuard allowedRoles={OFFICIAL_ROLES}>
          <div className="shrink-0">
            <MapHeatmapPanel mode={heatmapMode} onModeChange={setHeatmapMode} />
          </div>
        </RoleGuard>
      </div>

      {/* Details Slide-in Panel */}
      <div
        className={`absolute top-28 bottom-6 left-6 z-40 w-[28.25rem] transition-transform duration-500 ${
          isDetailCardOpen ? 'translate-x-0' : '-translate-x-[150%]'
        }`}
      >
        <ActiveEntityCard
          marker={selectedMarker}
          onClose={handleCloseDetailCard}
          onNavigate={() => {
            if (selectedMarker) {
              mapRef.current?.flyToMarker(selectedMarker);
            }
          }}
          onView360={() => {
            // View 360 trigger
          }}
          onReportProblem={() => {
            if (!selectedMarker) return;
            const campusId =
              selectedMarker.type === 'building'
                ? (selectedMarker.data as BuildingLocationDto).metadata?.campusId ?? activeCampusId
                : (selectedMarker.data as StructureDto).campusId;
            navigate('/reports', {
              state: {
                campusId,
                structureName: selectedMarker.name,
              },
            });
          }}
          onReportLostObject={() => {
            if (!selectedMarker) return;
            const campusId =
              selectedMarker.type === 'building'
                ? (selectedMarker.data as BuildingLocationDto).metadata?.campusId ?? activeCampusId
                : (selectedMarker.data as StructureDto).campusId;
            navigate('/objects', {
              state: {
                campusId,
                structureName: selectedMarker.name,
              },
            });
          }}
        />
      </div>
    </CampusMapCanvas>
  );
};
