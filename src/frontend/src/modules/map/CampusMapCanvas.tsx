import React from 'react';
import { createRoot, type Root } from 'react-dom/client';
import mapboxgl, { type Map as MapboxMap } from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

import { SquareButton } from '../../components/ui/SquareButton';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';
import { MapMarker } from '../../components/ui/MapMarker';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import type { CampusDto } from '../../dtos/campus/CampusDto';
import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';
import { UCT_LOADING_PHRASES } from '../../constants/loadingPhrases';

import PlusIcon from '../../assets/svg/icons/icon_plus.svg?react';
import MinusIcon from '../../assets/svg/icons/icon_minus.svg?react';
import TargetIcon from '../../assets/svg/icons/icon_target.svg?react';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN;
const MAP_STYLE = 'mapbox://styles/mapbox/standard';
export const CAMPUS_CENTER: [number, number] = [-72.6019, -38.7368];
export const CAMPUS_BOUNDS: [[number, number], [number, number]] = [
  [-72.635, -38.758],
  [-72.568, -38.716],
];
const MAP_MAX_BOUNDS: [[number, number], [number, number]] = [
  [-72.75, -38.85],
  [-72.45, -38.63],
];
const MIN_ZOOM = 12;
const MAX_ZOOM = 19;
const INITIAL_ZOOM = 14;
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

export const isWithinCampus = ([lng, lat]: [number, number]) =>
  lng >= CAMPUS_BOUNDS[0][0] &&
  lng <= CAMPUS_BOUNDS[1][0] &&
  lat >= CAMPUS_BOUNDS[0][1] &&
  lat <= CAMPUS_BOUNDS[1][1];

export const resolveBuildingCoordinate = (building: BuildingLocationDto): [number, number] => {
  const coordinate: [number, number] = [building.location.longitude, building.location.latitude];
  if (coordinate[0] !== 0 || coordinate[1] !== 0) return coordinate;
  const seed = hashString(building.id);
  const angle = ((seed % 360) * Math.PI) / 180;
  const radius = MOCK_SPREAD * (0.45 + ((seed % 50) / 50) * 0.55);
  return [
    CAMPUS_CENTER[0] + Math.cos(angle) * radius,
    CAMPUS_CENTER[1] + Math.sin(angle) * radius,
  ];
};

export const resolveStructureCoordinate = (structure: StructureDto): [number, number] => {
  const coordinate: [number, number] = [structure.longitude, structure.latitude];
  if (coordinate[0] !== 0 || coordinate[1] !== 0) return coordinate;
  const seed = hashString(structure.id);
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

export const flyToCoordinate = (
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
  handlers.forEach((handler) => (enabled ? handler.enable() : handler.disable()));
};

interface MarkerEntry {
  marker: mapboxgl.Marker;
  root: Root;
  lng: number;
  lat: number;
}

// Module-level persistent singleton so Mapbox only initializes once per session
let sharedContainerEl: HTMLDivElement | null = null;
let sharedMapInstance: MapboxMap | null = null;
let sharedMapLoaded = false;
let sharedMapError: string | null = null;
const sharedMarkers = new Map<string, MarkerEntry>();
const loadListeners = new Set<() => void>();
const errorListeners = new Set<(err: string) => void>();
let lastDragEndTimestamp = 0;
let isDraggingMarker = false;

function ensureSharedMap(host: HTMLDivElement): {
  containerEl: HTMLDivElement;
  map: MapboxMap | null;
  isLoaded: boolean;
  error: string | null;
} {
  if (!sharedContainerEl) {
    sharedContainerEl = document.createElement('div');
    sharedContainerEl.className = 'relative h-full w-full';
  }

  // Attach containerEl to the live DOM host BEFORE constructing mapboxgl.Map
  // so clientWidth / clientHeight and computed styles are valid from frame 0.
  if (sharedContainerEl.parentElement !== host) {
    host.appendChild(sharedContainerEl);
  }

  if (!MAPBOX_TOKEN) {
    return {
      containerEl: sharedContainerEl,
      map: null,
      isLoaded: false,
      error: null,
    };
  }

  if (!sharedMapInstance && !sharedMapError) {
    try {
      mapboxgl.accessToken = MAPBOX_TOKEN;
      const map = new mapboxgl.Map({
        container: sharedContainerEl,
        style: MAP_STYLE,
        center: CAMPUS_CENTER,
        zoom: INITIAL_ZOOM,
        pitch: INITIAL_PITCH,
        bearing: INITIAL_BEARING,
        maxBounds: MAP_MAX_BOUNDS,
        minZoom: MIN_ZOOM,
        maxZoom: MAX_ZOOM,
        renderWorldCopies: false,
        fadeDuration: 100,
        attributionControl: false,
      });

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
        map.resize();
        sharedMapLoaded = true;
        loadListeners.forEach((listener) => listener());
      });
      map.on('error', (event) => console.error('Mapbox error:', event.error));

      sharedMapInstance = map;
    } catch (error) {
      sharedMapError = error instanceof Error ? error.message : 'No se pudo inicializar Mapbox';
      errorListeners.forEach((listener) => listener(sharedMapError!));
    }
  } else if (sharedMapInstance) {
    sharedMapInstance.resize();
  }

  return {
    containerEl: sharedContainerEl,
    map: sharedMapInstance,
    isLoaded: sharedMapLoaded,
    error: sharedMapError,
  };
}

export interface CampusCamera {
  latitude: number;
  longitude: number;
  zoom: number;
  pitch: number;
  bearing: number;
}

export const getSharedMapCamera = (): CampusCamera | null => {
  if (!sharedMapInstance) return null;

  const center = sharedMapInstance.getCenter();
  return {
    latitude: center.lat,
    longitude: center.lng,
    zoom: sharedMapInstance.getZoom(),
    pitch: sharedMapInstance.getPitch(),
    bearing: sharedMapInstance.getBearing(),
  };
};

export const applySharedMapCamera = (camera: CampusCamera, smooth = false) => {
  if (!sharedMapInstance) return;

  if (smooth) {
    sharedMapInstance.flyTo({
      center: [camera.longitude, camera.latitude],
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: camera.bearing,
      duration: 900,
      essential: true,
    });
  } else {
    sharedMapInstance.jumpTo({
      center: [camera.longitude, camera.latitude],
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: camera.bearing,
    });
  }
};

export interface CampusMapHandle {
  flyToMarker: (marker: MapMarkerItem | { coordinates: [number, number] }) => void;
  flyToBuilding: (building: BuildingLocationDto) => void;
  flyToStructure: (structure: StructureDto) => void;
  flyToCampus: (campus: CampusDto) => void;
  getMap: () => MapboxMap | null;
}

interface CampusMapCanvasProps {
  markers?: MapMarkerItem[];
  areMarkersLoading?: boolean;
  selectedMarkerId?: string | null;
  onMarkerClick?: (marker: MapMarkerItem) => void;
  onMapClick?: (coords: [number, number]) => void;
  markersDraggable?: boolean;
  onMarkerDragEnd?: (marker: MapMarkerItem, coords: [number, number]) => void;
  cursorMode?: 'default' | 'crosshair' | 'grab' | 'pointer';
  children?: React.ReactNode;
}

export const CampusMapCanvas = React.forwardRef<CampusMapHandle, CampusMapCanvasProps>(
  (
    {
      markers,
      areMarkersLoading = false,
      selectedMarkerId = null,
      onMarkerClick,
      onMapClick,
      markersDraggable = false,
      onMarkerDragEnd,
      cursorMode = 'default',
      children,
    },
    ref
  ) => {
    const hostRef = React.useRef<HTMLDivElement | null>(null);
    const [isMapLoaded, setIsMapLoaded] = React.useState(sharedMapLoaded);
    const [mapError, setMapError] = React.useState<string | null>(sharedMapError);
    const [is3D, setIs3D] = React.useState(() =>
      sharedMapInstance ? sharedMapInstance.getPitch() > 1 : true
    );

    React.useImperativeHandle(
      ref,
      () => ({
        flyToMarker: (marker: MapMarkerItem | { coordinates: [number, number] }) => {
          if (!sharedMapInstance) return;
          flyToCoordinate(sharedMapInstance, marker.coordinates, {
            zoom: Math.max(sharedMapInstance.getZoom(), 17),
          });
        },
        flyToBuilding: (building: BuildingLocationDto) => {
          if (!sharedMapInstance) return;
          flyToCoordinate(sharedMapInstance, resolveBuildingCoordinate(building), {
            zoom: Math.max(sharedMapInstance.getZoom(), 17),
          });
        },
        flyToStructure: (structure: StructureDto) => {
          if (!sharedMapInstance) return;
          flyToCoordinate(sharedMapInstance, resolveStructureCoordinate(structure), {
            zoom: Math.max(sharedMapInstance.getZoom(), 17),
          });
        },
        flyToCampus: (campus: CampusDto) => {
          if (!sharedMapInstance) return;
          const coordinate: [number, number] = [campus.longitude, campus.latitude];
          const currently3D = sharedMapInstance.getPitch() > 1;
          const hasStoredCamera = campus.zoom > 0;
          setMapInteraction(sharedMapInstance, false);
          sharedMapInstance.once('moveend', () => {
            if (sharedMapInstance) setMapInteraction(sharedMapInstance, true);
          });
          flyToCoordinate(
            sharedMapInstance,
            isWithinCampus(coordinate) ? coordinate : CAMPUS_CENTER,
            {
              zoom: hasStoredCamera ? campus.zoom : INITIAL_ZOOM,
              pitch: hasStoredCamera ? campus.pitch : currently3D ? INITIAL_PITCH : 0,
              bearing: hasStoredCamera ? campus.bearing : currently3D ? INITIAL_BEARING : 0,
            }
          );
        },
        getMap: () => sharedMapInstance,
      }),
      []
    );

    // Attach persistent Mapbox container to current view host
    React.useEffect(() => {
      const host = hostRef.current;
      if (!host) return;

      const { map, isLoaded, error } = ensureSharedMap(host);
      setIsMapLoaded(isLoaded);
      setMapError(error);

      const handleLoad = () => setIsMapLoaded(true);
      const handleError = (err: string) => setMapError(err);
      loadListeners.add(handleLoad);
      errorListeners.add(handleError);

      const handlePitchEnd = () => {
        if (!map) return;
        const next = map.getPitch() > 1;
        setIs3D((prev) => (prev === next ? prev : next));
      };

      if (map) {
        setIs3D(map.getPitch() > 1);
        map.on('pitchend', handlePitchEnd);
        map.resize();
      }

      return () => {
        loadListeners.delete(handleLoad);
        errorListeners.delete(handleError);
        if (map) {
          map.off('pitchend', handlePitchEnd);
        }
      };
    }, []);

    // Dynamic map canvas cursor
    React.useEffect(() => {
      const map = sharedMapInstance;
      if (!map) return;
      const canvas = map.getCanvas();
      if (!canvas) return;

      if (cursorMode === 'crosshair') {
        canvas.style.cursor = 'crosshair';
      } else if (cursorMode === 'grab') {
        canvas.style.cursor = 'grab';
      } else if (cursorMode === 'pointer') {
        canvas.style.cursor = 'pointer';
      } else {
        canvas.style.cursor = '';
      }
    }, [cursorMode, isMapLoaded]);

    // Ground click listener
    React.useEffect(() => {
      const map = sharedMapInstance;
      if (!map || !onMapClick) return;

      const handleClick = (event: mapboxgl.MapMouseEvent) => {
        // If a marker is currently being dragged or was just dropped within 350ms, ignore ground click
        if (isDraggingMarker || Date.now() - lastDragEndTimestamp < 350) {
          return;
        }
        onMapClick([event.lngLat.lng, event.lngLat.lat]);
      };

      map.on('click', handleClick);
      return () => {
        map.off('click', handleClick);
      };
    }, [onMapClick, isMapLoaded]);

    const callbacksRef = React.useRef({
      onMarkerClick,
      onMarkerDragEnd,
      markers,
    });
    callbacksRef.current = {
      onMarkerClick,
      onMarkerDragEnd,
      markers,
    };

    // Unified sync for any MapMarkerItem
    React.useEffect(() => {
      const map = sharedMapInstance;
      if (!map || !isMapLoaded) return;

      const activeMarkers = markers ?? [];
      const currentIds = new Set(activeMarkers.map((m) => m.id));

      sharedMarkers.forEach((entry, id) => {
        if (!currentIds.has(id)) {
          entry.marker.remove();
          entry.root.unmount();
          sharedMarkers.delete(id);
        }
      });

      activeMarkers.forEach((markerItem) => {
        const isActive = selectedMarkerId === markerItem.id;
        const [lng, lat] = markerItem.coordinates;
        const color = isActive ? 'green' : (markerItem.color ?? 'blue');

        const content = (
          <MapMarker
            icon={markerItem.icon}
            color={color}
            isActive={isActive}
            onClick={(e) => {
              e.stopPropagation();
              callbacksRef.current.onMarkerClick?.(markerItem);
            }}
          />
        );

        let entry = sharedMarkers.get(markerItem.id);
        if (!entry) {
          const element = document.createElement('div');
          const root = createRoot(element);
          const marker = new mapboxgl.Marker({
            element,
            anchor: 'bottom',
            draggable: !!markersDraggable,
          })
            .setLngLat([lng, lat])
            .addTo(map);

          marker.on('dragstart', () => {
            isDraggingMarker = true;
            lastDragEndTimestamp = Date.now();
            const current =
              callbacksRef.current.markers?.find((m) => m.id === markerItem.id) || markerItem;
            callbacksRef.current.onMarkerClick?.(current);
          });

          marker.on('drag', () => {
            isDraggingMarker = true;
            lastDragEndTimestamp = Date.now();
          });

          marker.on('dragend', () => {
            isDraggingMarker = false;
            lastDragEndTimestamp = Date.now();
            const lngLat = marker.getLngLat();
            const current =
              callbacksRef.current.markers?.find((m) => m.id === markerItem.id) || markerItem;
            callbacksRef.current.onMarkerClick?.(current);
            callbacksRef.current.onMarkerDragEnd?.(current, [lngLat.lng, lngLat.lat]);
          });

          entry = { marker, root, lng, lat };
          sharedMarkers.set(markerItem.id, entry);
        } else {
          entry.marker.setDraggable(!!markersDraggable);
          if (entry.lng !== lng || entry.lat !== lat) {
            entry.marker.setLngLat([lng, lat]);
            entry.lng = lng;
            entry.lat = lat;
          }
        }

        entry.root.render(content);
      });
    }, [markers, isMapLoaded, selectedMarkerId, markersDraggable]);

    const handleZoomIn = () => sharedMapInstance?.zoomIn({ duration: 300 });
    const handleZoomOut = () => sharedMapInstance?.zoomOut({ duration: 300 });

    const handleResetView = () => {
      const map = sharedMapInstance;
      if (!map) return;
      flyToCoordinate(map, CAMPUS_CENTER, {
        zoom: INITIAL_ZOOM,
        pitch: is3D ? INITIAL_PITCH : 0,
        bearing: is3D ? INITIAL_BEARING : 0,
      });
    };

    const handleToggleDimension = () => {
      const map = sharedMapInstance;
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

    const isDataLoading = !isMapLoaded || areMarkersLoading;

    return (
      <div className="w-full h-full absolute inset-0 overflow-hidden">
        <div ref={hostRef} className="h-full w-full" />

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
                {mapError ??
                  'Define VITE_MAPBOX_TOKEN en src/frontend/.env y reinicia el servidor o recompila la imagen.'}
              </p>
            </div>
          </div>
        )}

        {/* Map camera controls */}
        <div className="absolute bottom-6 right-6 z-20 flex items-end gap-6">
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

        {children}
      </div>
    );
  }
);

CampusMapCanvas.displayName = 'CampusMapCanvas';
