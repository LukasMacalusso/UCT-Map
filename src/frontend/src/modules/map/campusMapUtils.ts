import type { Map as MapboxMap } from 'mapbox-gl';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';

export const CAMPUS_CENTER: [number, number] = [-72.6019, -38.7368];
export const CAMPUS_BOUNDS: [[number, number], [number, number]] = [
  [-72.635, -38.758],
  [-72.568, -38.716],
];
export const MAP_MAX_BOUNDS: [[number, number], [number, number]] = [
  [-73.45, -39.95],
  [-72.10, -38.55],
];
export const MIN_ZOOM = 9;
export const MAX_ZOOM = 19;
export const INITIAL_ZOOM = 14;
export const INITIAL_PITCH = 50;
export const INITIAL_BEARING = -20;

export const MOCK_SPREAD = 0.006;

export const hashString = (value: string): number => {
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

export interface CameraOptions {
  zoom?: number;
  pitch?: number;
  bearing?: number;
  duration?: number;
}

export const easeInOutCubic = (t: number): number =>
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

export interface CampusCamera {
  latitude: number;
  longitude: number;
  zoom: number;
  pitch: number;
  bearing: number;
}

let sharedMapInstanceRef: MapboxMap | null = null;

export const setSharedMapInstanceRef = (instance: MapboxMap | null) => {
  sharedMapInstanceRef = instance;
};

export const getSharedMapInstanceRef = (): MapboxMap | null => sharedMapInstanceRef;

export const getSharedMapCamera = (): CampusCamera | null => {
  if (!sharedMapInstanceRef) return null;

  const center = sharedMapInstanceRef.getCenter();
  return {
    latitude: center.lat,
    longitude: center.lng,
    zoom: sharedMapInstanceRef.getZoom(),
    pitch: sharedMapInstanceRef.getPitch(),
    bearing: sharedMapInstanceRef.getBearing(),
  };
};

export const applySharedMapCamera = (camera: CampusCamera, smooth = false) => {
  if (!sharedMapInstanceRef) return;

  if (smooth) {
    sharedMapInstanceRef.flyTo({
      center: [camera.longitude, camera.latitude],
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: camera.bearing,
      duration: 900,
      essential: true,
    });
  } else {
    sharedMapInstanceRef.jumpTo({
      center: [camera.longitude, camera.latitude],
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: camera.bearing,
    });
  }
};
