import React from 'react';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { SquareButton } from '../components/ui/SquareButton';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import { RoleGuard } from '../router/RoleGuard';
import { MapSidePanel } from '../modules/map/MapSidePanel';
import { MapHeatmapPanel } from '../modules/map/MapHeatmapPanel';
import { useBuildingLocations, useCampuses } from '../hooks/useCampus';
import { ActiveBuildingCard } from '../modules/map/ActiveBuildingCard';
import { CampusMapCanvas, type CampusMapHandle } from '../modules/map/CampusMapCanvas';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import { textPageColors } from '../constants/colors';
import { OFFICIAL_ROLES } from '../constants/role';

export const MapView = () => {
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isSidePanelOpen, setIsSidePanelOpen] = React.useState(false);
  const [selectedBuilding, setSelectedBuilding] = React.useState<BuildingLocationDto | null>(null);
  const [isBuildingCardOpen, setIsBuildingCardOpen] = React.useState(false);
  const [selectedCampus, setSelectedCampus] = React.useState('');

  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const activeCampusId = selectedCampus || campuses?.[0]?.id || '';
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    activeCampusId || undefined,
    !areCampusesLoading
  );

  const mapRef = React.useRef<CampusMapHandle | null>(null);
  const cardCloseTimeoutRef = React.useRef<number | null>(null);

  const mapSearchOptions = (buildings ?? []).map((building) => ({
    value: building.id,
    label: building.name,
  }));

  const handleBuildingClick = React.useCallback((building: BuildingLocationDto) => {
    if (cardCloseTimeoutRef.current) {
      window.clearTimeout(cardCloseTimeoutRef.current);
      cardCloseTimeoutRef.current = null;
    }
    setSelectedBuilding(building);
    setIsBuildingCardOpen(true);
    mapRef.current?.flyToBuilding(building);
  }, []);

  const handleCloseBuildingCard = React.useCallback(() => {
    setIsBuildingCardOpen(false);
    cardCloseTimeoutRef.current = window.setTimeout(() => {
      setSelectedBuilding(null);
      cardCloseTimeoutRef.current = null;
    }, 500);
  }, []);

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    const campus = campuses?.find((item) => item.id === value);
    if (!campus) return;
    mapRef.current?.flyToCampus(campus);
  };

  return (
    <CampusMapCanvas
      ref={mapRef}
      buildings={buildings}
      areBuildingsLoading={areBuildingsLoading}
      selectedBuildingId={selectedBuilding?.id ?? null}
      onBuildingClick={handleBuildingClick}
    >
      <div className="absolute top-6 right-6 left-6 sm:left-auto z-10 flex flex-row gap-3 items-end">
        <div className="w-full min-w-0 sm:w-72 lg:w-80">
          <SearchInput
            label="Búsqueda"
            labelColor={textPageColors.dark}
            placeholder="Buscar Edificio..."
            value={searchQuery}
            onChange={(val) => setSearchQuery(val)}
            icon={<SearchIcon className="w-6 h-6 text-gray-500" />}
            options={mapSearchOptions}
            onSelectOption={(option) => {
              const building = buildings?.find((item) => item.id === option.value);
              if (building) handleBuildingClick(building);
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
            <MapHeatmapPanel />
          </div>
        </RoleGuard>
      </div>

      {/* Building Details Slide-in Panel */}
      <div
        className={`absolute top-28 bottom-6 left-6 z-40 w-[28.25rem] transition-transform duration-500 ${
          isBuildingCardOpen ? 'translate-x-0' : '-translate-x-[150%]'
        }`}
      >
        <ActiveBuildingCard building={selectedBuilding} onClose={handleCloseBuildingCard} />
      </div>
    </CampusMapCanvas>
  );
};
