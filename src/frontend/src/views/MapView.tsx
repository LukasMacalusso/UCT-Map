import React from 'react';
import { createRoot, type Root } from 'react-dom/client';
import mapboxgl, { type Map as MapboxMap } from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { SquareButton } from '../components/ui/SquareButton';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import PlusIcon from '../assets/svg/icons/icon_plus.svg?react';
import MinusIcon from '../assets/svg/icons/icon_minus.svg?react';
import TargetIcon from '../assets/svg/icons/icon_target.svg?react';
import PencilIcon from '../assets/svg/icons/icon_pencil.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import { RoleGuard } from '../router/RoleGuard';
import { MapEditorPanel } from '../modules/admin/MapEditorPanel';
import { BuildingFormModal } from '../modules/admin/BuildingFormModal';
import { MapSidePanel } from '../modules/map/MapSidePanel';
import { MapHeatmapPanel } from '../modules/map/MapHeatmapPanel';
import { useBuildingLocations, useCampuses } from '../hooks/useCampus';
import { MapMarker } from '../components/ui/MapMarker';
import { ActiveBuildingCard } from '../modules/map/ActiveBuildingCard';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import { textPageColors } from '../constants/colors';
import { OFFICIAL_ROLES, Role } from '../constants/role';
import { UCT_LOADING_PHRASES } from '../constants/loadingPhrases';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN;
const MAP_STYLE = 'mapbox://styles/mapbox/standard';
const CAMPUS_CENTER: [number, number] = [-72.6019, -38.7368];
const CAMPUS_BOUNDS: [[number, number], [number, number]] = [
  [-72.635, -38.758],
  [-72.568, -38.716],
];
const MIN_ZOOM = 14;
const MAX_ZOOM = 19;
const INITIAL_ZOOM = 15;
const INITIAL_PITCH = 50;
const INITIAL_BEARING = -20;

const MOCK_SPREAD = 0.006;

const hashString = (value: string): number => {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i++) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return Math.abs(hash);
};

const isWithinCampus = ([lng, lat]: [number, number]) =>
  lng >= CAMPUS_BOUNDS[0][0] &&
  lng <= CAMPUS_BOUNDS[1][0] &&
  lat >= CAMPUS_BOUNDS[0][1] &&
  lat <= CAMPUS_BOUNDS[1][1];

const resolveBuildingCoordinate = (building: BuildingLocationDto): [number, number] => {
  const coordinate: [number, number] = [building.location.longitude, building.location.latitude];
  if (isWithinCampus(coordinate)) return coordinate;
  const seed = hashString(building.id);
  const angle = ((seed % 360) * Math.PI) / 180;
  const radius = MOCK_SPREAD * (0.45 + ((seed % 50) / 50) * 0.55);
  return [
    CAMPUS_CENTER[0] + Math.cos(angle) * radius,
    CAMPUS_CENTER[1] + Math.sin(angle) * radius,
  ];
};

interface CameraOptions {
  zoom?: number;
  pitch?: number;
  bearing?: number;
  duration?: number;
}

const easeInOutCubic = (t: number): number =>
  t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

const flyToCoordinate = (
  map: MapboxMap,
  center: [number, number],
  options: CameraOptions = {}
) => {
  map.flyTo({
    center,
    zoom: options.zoom ?? map.getZoom(),
    pitch: options.pitch ?? map.getPitch(),
    bearing: options.bearing ?? map.getBearing(),
    duration: options.duration ?? 950,
    curve: 1.42,
    speed: 1.2,
    essential: true,
    easing: easeInOutCubic,
  });
};

const setMapInteraction = (map: MapboxMap, enabled: boolean) => {
  const handlers = [
    map.dragPan,
    map.scrollZoom,
    map.boxZoom,
    map.dragRotate,
    map.keyboard,
    map.doubleClickZoom,
    map.touchZoomRotate,
    map.touchPitch,
  ];
  handlers.forEach(handler => (enabled ? handler.enable() : handler.disable()));
};

interface MarkerEntry {
  marker: mapboxgl.Marker;
  root: Root;
}

export const MapView = () => {
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isEditorOpen, setIsEditorOpen] = React.useState(false);
  const [isSidePanelOpen, setIsSidePanelOpen] = React.useState(false);
  const [isModalOpen, setIsModalOpen] = React.useState(false);
  const [selectedBuilding, setSelectedBuilding] = React.useState<BuildingLocationDto | null>(null);
  const [isBuildingCardOpen, setIsBuildingCardOpen] = React.useState(false);
  const [isMapLoaded, setIsMapLoaded] = React.useState(false);
  const [mapError, setMapError] = React.useState<string | null>(null);
  const [selectedCampus, setSelectedCampus] = React.useState('');
  const [is3D, setIs3D] = React.useState(true);

  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const activeCampusId = selectedCampus || campuses?.[0]?.id || '';
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    activeCampusId || undefined,
    !areCampusesLoading,
  );

  const containerRef = React.useRef<HTMLDivElement | null>(null);
  const mapRef = React.useRef<MapboxMap | null>(null);
  const markersRef = React.useRef<Map<string, MarkerEntry>>(new Map());
  const removalRef = React.useRef<number | null>(null);
  const cardCloseTimeoutRef = React.useRef<number | null>(null);

  const mapSearchOptions = (buildings ?? []).map((building) => ({
    value: building.id,
    label: building.name,
  }));

  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === 'p') {
        setIsModalOpen(prev => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  React.useEffect(() => {
    if (removalRef.current !== null) {
      window.clearTimeout(removalRef.current);
      removalRef.current = null;
    }

    if (!MAPBOX_TOKEN || !containerRef.current || mapRef.current) return;

    let map: MapboxMap;
    try {
      mapboxgl.accessToken = MAPBOX_TOKEN;
      map = new mapboxgl.Map({
        container: containerRef.current,
        style: MAP_STYLE,
        center: CAMPUS_CENTER,
        zoom: INITIAL_ZOOM,
        pitch: INITIAL_PITCH,
        bearing: INITIAL_BEARING,
        maxBounds: CAMPUS_BOUNDS,
        minZoom: MIN_ZOOM,
        maxZoom: MAX_ZOOM,
        renderWorldCopies: false,
        fadeDuration: 100,
        attributionControl: false,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'No se pudo inicializar Mapbox';
      queueMicrotask(() => setMapError(message));
      return;
    }

    map.on('style.load', () => {
      try {
        map.setConfigProperty('basemap', 'show3dObjects', true);
        map.setConfigProperty('basemap', 'show3dTrees', true);
        map.setConfigProperty('basemap', 'show3dBuildings', false);
        map.setConfigProperty('basemap', 'show3dLandmarks', false);
        map.setConfigProperty('basemap', 'show3dFacades', false);
        map.setConfigProperty('basemap', 'showPointOfInterestLabels', false);
        map.setConfigProperty('basemap', 'lightPreset', 'day');
      } catch (error) {
        console.warn('Mapbox config error:', error);
      }
    });

    map.addControl(new mapboxgl.AttributionControl({ compact: true }), 'bottom-right');
    map.on('load', () => {
      setIsMapLoaded(true);
    });
    map.on('error', (event) => console.error('Mapbox error:', event.error));

    map.on('pitchend', () => {
      const next = map.getPitch() > 1;
      setIs3D((prev) => (prev === next ? prev : next));
    });
    mapRef.current = map;

    const markers = markersRef.current;

    return () => {
      removalRef.current = window.setTimeout(() => {
        markers.forEach(({ marker, root }) => {
          marker.remove();
          root.unmount();
        });
        markers.clear();
        mapRef.current?.remove();
        mapRef.current = null;
        setIsMapLoaded(false);
        removalRef.current = null;
      }, 150);
    };
  }, []);

  const handleBuildingClick = React.useCallback((building: BuildingLocationDto) => {
    if (cardCloseTimeoutRef.current) {
      window.clearTimeout(cardCloseTimeoutRef.current);
      cardCloseTimeoutRef.current = null;
    }
    setSelectedBuilding(building);
    setIsBuildingCardOpen(true);
    const map = mapRef.current;
    if (!map) return;
    flyToCoordinate(map, resolveBuildingCoordinate(building), {
      zoom: Math.max(map.getZoom(), 17),
    });
  }, []);

  const handleCloseBuildingCard = React.useCallback(() => {
    setIsBuildingCardOpen(false);
    cardCloseTimeoutRef.current = window.setTimeout(() => {
      setSelectedBuilding(null);
      cardCloseTimeoutRef.current = null;
    }, 500);
  }, []);

  React.useEffect(() => {
    const map = mapRef.current;
    if (!map || !isMapLoaded || !buildings) return;

    const currentIds = new Set(buildings.map(building => building.id));

    markersRef.current.forEach((entry, id) => {
      if (!currentIds.has(id)) {
        entry.marker.remove();
        entry.root.unmount();
        markersRef.current.delete(id);
      }
    });

    buildings.forEach(building => {
      const isActive = selectedBuilding?.id === building.id;
      const content = (
        <MapMarker
          icon={<BuildingIcon className="w-5 h-5" />}
          color={isActive ? 'green' : 'blue'}
          isActive={isActive}
          onClick={(e) => {
            e.stopPropagation();
            handleBuildingClick(building);
          }}
        />
      );

      let entry = markersRef.current.get(building.id);
      if (!entry) {
        const element = document.createElement('div');
        const root = createRoot(element);
        const marker = new mapboxgl.Marker({ element, anchor: 'bottom' })
          .setLngLat(resolveBuildingCoordinate(building))
          .addTo(map);
        entry = { marker, root };
        markersRef.current.set(building.id, entry);
      }
      entry.root.render(content);
    });
  }, [buildings, isMapLoaded, selectedBuilding, handleBuildingClick]);

  const handleZoomIn = () => mapRef.current?.zoomIn({ duration: 300 });
  const handleZoomOut = () => mapRef.current?.zoomOut({ duration: 300 });

  const handleResetView = () => {
    const map = mapRef.current;
    if (!map) return;
    flyToCoordinate(map, CAMPUS_CENTER, {
      zoom: INITIAL_ZOOM,
      pitch: is3D ? INITIAL_PITCH : 0,
      bearing: is3D ? INITIAL_BEARING : 0,
    });
  };

  const handleCampusChange = (value: string) => {
    setSelectedCampus(value);
    const map = mapRef.current;
    const campus = campuses?.find((item) => item.id === value);
    if (!map || !campus) return;
    const coordinate: [number, number] = [campus.longitude, campus.latitude];
    setMapInteraction(map, false);
    map.once('moveend', () => setMapInteraction(map, true));
    flyToCoordinate(map, isWithinCampus(coordinate) ? coordinate : CAMPUS_CENTER, {
      zoom: INITIAL_ZOOM,
      pitch: is3D ? INITIAL_PITCH : 0,
      bearing: is3D ? INITIAL_BEARING : 0,
    });
  };

  const handleToggleDimension = () => {
    const map = mapRef.current;
    if (!map) return;
    const next = !is3D;
    setIs3D(next);
    const { lng, lat } = map.getCenter();
    flyToCoordinate(map, [lng, lat], {
      zoom: map.getZoom(),
      pitch: next ? INITIAL_PITCH : 0,
      bearing: next ? INITIAL_BEARING : 0,
    });
  };

  const isDataLoading = !isMapLoaded || areBuildingsLoading;

  return (
    <div className="w-full h-full absolute inset-0 overflow-hidden">
      <div ref={containerRef} className="h-full w-full" />

      {MAPBOX_TOKEN && !mapError && isDataLoading && (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-page-white/70 backdrop-blur-sm">
          <LoadingSpinner size="xl" texts={UCT_LOADING_PHRASES} />
        </div>
      )}

      {(!MAPBOX_TOKEN || mapError) && (
        <div className="absolute inset-0 z-30 flex items-center justify-center pointer-events-none p-4">
          <div className="bg-white/95 rounded-2xl shadow-xl px-6 py-5 max-w-md text-center">
            <p className="text-page-dark font-semibold">
              {mapError ? 'No se pudo cargar el mapa' : 'Falta configurar Mapbox'}
            </p>
            <p className="text-sm text-gray-600 mt-1 break-words">
              {mapError ?? 'Define VITE_MAPBOX_TOKEN en src/frontend/.env y reinicia el servidor o recompila la imagen.'}
            </p>
          </div>
        </div>
      )}

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

        <RoleGuard allowedRoles={[Role.Admin]}>
          <SquareButton
            onClick={() => setIsEditorOpen(!isEditorOpen)}
            title="Editar mapa"
            className={isEditorOpen ? '!bg-page-blue !text-white' : ''}
          >
            <PencilIcon className="w-7 h-7" />
          </SquareButton>
        </RoleGuard>
      </div>

      <div className="absolute bottom-6 right-6 z-20 flex items-end gap-6">

        {/* Animate container */}
        <RoleGuard allowedRoles={[Role.Admin]}>
          <div
            className={`transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] ${
              isEditorOpen ? 'translate-y-0 opacity-100 pointer-events-auto' : 'translate-y-10 opacity-0 pointer-events-none'
            }`}
          >
            <MapEditorPanel />
          </div>
        </RoleGuard>

        {/* Map controls */}
        <div className="flex flex-row items-center gap-2">
          <SquareButton
            onClick={handleToggleDimension}
            title={is3D ? 'Cambiar a vista 2D' : 'Cambiar a vista 3D'}
            className={is3D ? '!bg-page-blue !text-white' : ''}
          >
            <span className="text-base font-extrabold leading-none">{is3D ? '3D' : '2D'}</span>
          </SquareButton>

          <SquareButton onClick={handleResetView} title="Centrar mapa">
            <TargetIcon className="w-7 h-7" />
          </SquareButton>

          <div className="flex flex-row rounded-2xl bg-page-white shadow-sm">
            <SquareButton
              onClick={handleZoomIn}
              title="Acercar mapa"
              className="!rounded-r-none !shadow-none active:!scale-100"
            >
              <PlusIcon className="w-8 h-8" />
            </SquareButton>
            <SquareButton
              onClick={handleZoomOut}
              title="Alejar mapa"
              className="!rounded-l-none !shadow-none active:!scale-100"
            >
              <MinusIcon className="w-8 h-8" />
            </SquareButton>
          </div>
        </div>
      </div>

      {/* Side Panel */}
      <div className={`absolute top-28 bottom-24 right-6 z-40 w-[28.25rem] flex flex-col gap-3 transition-transform duration-500 ${
        isSidePanelOpen ? 'translate-x-0' : 'translate-x-[150%]'
      }`}>
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
      <div className={`absolute top-28 bottom-6 left-6 z-40 w-[28.25rem] transition-transform duration-500 ${
        isBuildingCardOpen ? 'translate-x-0' : '-translate-x-[150%]'
      }`}>
        <ActiveBuildingCard
          building={selectedBuilding}
          onClose={handleCloseBuildingCard}
        />
      </div>

      {/* Edit modal */}
      {isModalOpen && <BuildingFormModal onClose={() => setIsModalOpen(false)} />}
    </div>
  );
};
