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
import { MapHeatmapPanel } from '../modules/map/MapHeatmapPanel';
import { useBuildingLocations, useCampuses, useStructures } from '../hooks/useCampus';
import { ActiveBuildingCard } from '../modules/map/ActiveBuildingCard';
import { ActiveStructureCard } from '../modules/map/ActiveStructureCard';
import { CampusMapCanvas, type CampusMapHandle } from '../modules/map/CampusMapCanvas';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../dtos/campus/StructureDto';
import { textPageColors } from '../constants/colors';
import { OFFICIAL_ROLES } from '../constants/role';

export const MapView = () => {
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isSidePanelOpen, setIsSidePanelOpen] = React.useState(false);
  const [selectedBuilding, setSelectedBuilding] = React.useState<BuildingLocationDto | null>(null);
  const [selectedStructure, setSelectedStructure] = React.useState<StructureDto | null>(null);
  const [isBuildingCardOpen, setIsBuildingCardOpen] = React.useState(false);
  const [isStructureCardOpen, setIsStructureCardOpen] = React.useState(false);
  const [selectedCampus, setSelectedCampus] = React.useState('');

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

  const mapRef = React.useRef<CampusMapHandle | null>(null);
  const cardCloseTimeoutRef = React.useRef<number | null>(null);
  const navigate = useNavigate();

  const mapSearchOptions = [
    ...(buildings ?? []).map((building) => ({
      value: `building:${building.id}`,
      label: `${building.name} (Edificio)`,
    })),
    ...(structures ?? []).map((structure) => ({
      value: `structure:${structure.id}`,
      label: `${structure.name} (Estructura)`,
    })),
  ];

  const handleBuildingClick = React.useCallback((building: BuildingLocationDto) => {
    if (cardCloseTimeoutRef.current) {
      window.clearTimeout(cardCloseTimeoutRef.current);
      cardCloseTimeoutRef.current = null;
    }
    setIsStructureCardOpen(false);
    setSelectedStructure(null);

    setSelectedBuilding(building);
    setIsBuildingCardOpen(true);
    mapRef.current?.flyToBuilding(building);
  }, []);

  const handleStructureClick = React.useCallback((structure: StructureDto) => {
    if (cardCloseTimeoutRef.current) {
      window.clearTimeout(cardCloseTimeoutRef.current);
      cardCloseTimeoutRef.current = null;
    }
    setIsBuildingCardOpen(false);
    setSelectedBuilding(null);

    setSelectedStructure(structure);
    setIsStructureCardOpen(true);
    mapRef.current?.flyToStructure(structure);
  }, []);

  const handleCloseBuildingCard = React.useCallback(() => {
    setIsBuildingCardOpen(false);
    cardCloseTimeoutRef.current = window.setTimeout(() => {
      setSelectedBuilding(null);
      cardCloseTimeoutRef.current = null;
    }, 500);
  }, []);

  const handleCloseStructureCard = React.useCallback(() => {
    setIsStructureCardOpen(false);
    cardCloseTimeoutRef.current = window.setTimeout(() => {
      setSelectedStructure(null);
      cardCloseTimeoutRef.current = null;
    }, 500);
  }, []);

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    handleCloseBuildingCard();
    handleCloseStructureCard();
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
      structures={structures}
      areStructuresLoading={areStructuresLoading}
      selectedStructureId={selectedStructure?.id ?? null}
      onStructureClick={handleStructureClick}
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
              const [type, id] = option.value.split(':');
              if (type === 'building') {
                const b = buildings?.find((item) => item.id === id);
                if (b) handleBuildingClick(b);
              } else if (type === 'structure') {
                const s = structures?.find((item) => item.id === id);
                if (s) handleStructureClick(s);
              }
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

      {/* Details Slide-in Panel (Building or Structure) */}
      <div
        className={`absolute top-28 bottom-6 left-6 z-40 w-[28.25rem] transition-transform duration-500 ${
          isBuildingCardOpen || isStructureCardOpen ? 'translate-x-0' : '-translate-x-[150%]'
        }`}
      >
        {selectedBuilding && isBuildingCardOpen && (
          <ActiveBuildingCard
            building={selectedBuilding}
            onClose={handleCloseBuildingCard}
            onReportProblem={() => {
              if (!selectedBuilding) return;
              navigate('/reports', {
                state: {
                  campusId: selectedBuilding.metadata?.campusId ?? activeCampusId,
                  structureName: selectedBuilding.name,
                },
              });
            }}
            onReportLostObject={() => {
              if (!selectedBuilding) return;
              navigate('/objects', {
                state: {
                  campusId: selectedBuilding.metadata?.campusId ?? activeCampusId,
                  structureName: selectedBuilding.name,
                },
              });
            }}
          />
        )}

        {selectedStructure && isStructureCardOpen && (
          <ActiveStructureCard
            structure={selectedStructure}
            onClose={handleCloseStructureCard}
            onNavigate={() => {
              if (selectedStructure) {
                mapRef.current?.flyToStructure(selectedStructure);
              }
            }}
            onReportProblem={() => {
              if (!selectedStructure) return;
              navigate('/reports', {
                state: {
                  campusId: selectedStructure.campusId,
                  structureName: selectedStructure.name,
                },
              });
            }}
            onReportLostObject={() => {
              if (!selectedStructure) return;
              navigate('/objects', {
                state: {
                  campusId: selectedStructure.campusId,
                  structureName: selectedStructure.name,
                },
              });
            }}
          />
        )}
      </div>
    </CampusMapCanvas>
  );
};
