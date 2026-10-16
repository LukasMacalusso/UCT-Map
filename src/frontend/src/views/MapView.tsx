import React from 'react';
import { createRoot, type Root } from 'react-dom/client';
import mapboxgl, { type Map as MapboxMap } from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { SquareButton } from '../components/ui/SquareButton';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import PlusIcon from '../assets/svg/icons/icon_plus.svg?react';
import MinusIcon from '../assets/svg/icons/icon_minus.svg?react';
import TargetIcon from '../assets/svg/icons/icon_target.svg?react';
import PencilIcon from '../assets/svg/icons/icon_pencil.svg?react';
import { RoleGuard } from '../router/RoleGuard';
import { MapEditorPanel } from '../modules/admin/MapEditorPanel';
import { BuildingFormModal } from '../modules/admin/BuildingFormModal';
import { useBuildingLocations } from '../hooks/useCampus';
import { MapMarker } from '../components/ui/MapMarker';
import { ActiveBuildingCard } from '../modules/map/ActiveBuildingCard';
import type { BuildingLocationDto } from '../dtos/campus/BuildingLocationDto';
import { Role } from '../constants/role';

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

interface MarkerEntry {
  marker: mapboxgl.Marker;
  root: Root;
}

export const MapView = () => {
  const [searchQuery, setSearchQuery] = React.useState('');
  const [isEditorOpen, setIsEditorOpen] = React.useState(false);
  const [isModalOpen, setIsModalOpen] = React.useState(false);
  const [selectedBuilding, setSelectedBuilding] = React.useState<BuildingLocationDto | null>(null);
  const [isMapLoaded, setIsMapLoaded] = React.useState(false);
  const [mapError, setMapError] = React.useState<string | null>(null);

  const { data: buildings } = useBuildingLocations();

  const containerRef = React.useRef<HTMLDivElement | null>(null);
  const mapRef = React.useRef<MapboxMap | null>(null);
  const markersRef = React.useRef<Map<string, MarkerEntry>>(new Map());
  const removalRef = React.useRef<number | null>(null);

  const mapSearchOptions = [
    { value: 'biblioteca', label: 'Biblioteca Central' },
    { value: 'casino', label: 'Casino' },
    { value: 'edificio-c', label: 'Edificio C' },
    { value: 'gimnasio', label: 'Gimnasio' },
    { value: 'auditorio', label: 'Auditorio Principal' }
  ];

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
        map.setConfigProperty('basemap', 'show3dObjects', false);
        map.setConfigProperty('basemap', 'show3dLandmarks', false);
        map.setConfigProperty('basemap', 'showPointOfInterestLabels', false);
      } catch (error) {
        console.warn('Mapbox config error:', error);
      }
    });

    map.addControl(new mapboxgl.AttributionControl({ compact: true }), 'bottom-left');
    map.on('load', () => setIsMapLoaded(true));
    map.on('error', (event) => console.error('Mapbox error:', event.error));
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
    setSelectedBuilding(building);
    const map = mapRef.current;
    if (!map) return;
    map.flyTo({
      center: [building.location.longitude, building.location.latitude],
      zoom: Math.max(map.getZoom(), 17),
      duration: 900,
    });
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
          .setLngLat([building.location.longitude, building.location.latitude])
          .addTo(map);
        entry = { marker, root };
        markersRef.current.set(building.id, entry);
      }
      entry.root.render(content);
    });
  }, [buildings, isMapLoaded, selectedBuilding, handleBuildingClick]);

  const handleZoomIn = () => mapRef.current?.zoomIn({ duration: 300 });
  const handleZoomOut = () => mapRef.current?.zoomOut({ duration: 300 });
  const handleResetView = () =>
    mapRef.current?.flyTo({
      center: CAMPUS_CENTER,
      zoom: INITIAL_ZOOM,
      pitch: INITIAL_PITCH,
      bearing: INITIAL_BEARING,
      duration: 900,
    });

  return (
    <div className="w-full h-full absolute inset-0 overflow-hidden">
      <div ref={containerRef} className="h-full w-full" />

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

      <div className="absolute top-6 right-6 z-10 flex flex-col gap-3 items-end">
        <div className="w-80">
          <SearchInput
            label="Búsqueda"
            placeholder="Buscar Edificio..."
            value={searchQuery}
            onChange={(val) => setSearchQuery(val)}
            icon={<SearchIcon className="w-6 h-6 text-gray-500" />}
            options={mapSearchOptions}
          />
        </div>

        <div className="w-80">
          <Select
            label="Campus"
            options={[
              { value: 'campus1', label: 'Campus San Juan Pablo II' },
              { value: 'campus2', label: 'Campus Norte' }
            ]}
            value="campus1"
            icon={<BuildingIcon className="w-6 h-6 text-gray-700" />}
          />
        </div>
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
        <div className="flex flex-col gap-2">
          <RoleGuard allowedRoles={[Role.Admin]}>
            <SquareButton
              onClick={() => setIsEditorOpen(!isEditorOpen)}
              title="Editar mapa"
              className={isEditorOpen ? '!bg-page-blue !text-white' : ''}
            >
              <PencilIcon className="w-7 h-7" />
            </SquareButton>
          </RoleGuard>
          <SquareButton onClick={handleZoomIn} title="Acercar mapa">
            <PlusIcon className="w-8 h-8" />
          </SquareButton>
          <SquareButton onClick={handleZoomOut} title="Alejar mapa">
            <MinusIcon className="w-8 h-8" />
          </SquareButton>
          <SquareButton onClick={handleResetView} title="Centrar mapa">
            <TargetIcon className="w-7 h-7" />
          </SquareButton>
        </div>
      </div>

      {/* Building Details Slide-in Panel */}
      <div className={`absolute top-24 bottom-6 left-6 w-96 transition-transform duration-500 z-40 ${
        selectedBuilding ? 'translate-x-0' : '-translate-x-[150%]'
      }`}>
        <ActiveBuildingCard
          building={selectedBuilding}
          onClose={() => setSelectedBuilding(null)}
        />
      </div>

      {/* Edit modal */}
      {isModalOpen && <BuildingFormModal onClose={() => setIsModalOpen(false)} />}
    </div>
  );
};
