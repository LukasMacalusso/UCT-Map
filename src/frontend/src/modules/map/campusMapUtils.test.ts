import { describe, it, expect, vi } from 'vitest';
import {
  CAMPUS_CENTER,
  CAMPUS_BOUNDS,
  isWithinCampus,
  hashString,
  resolveBuildingCoordinate,
  resolveStructureCoordinate,
  flyToCoordinate,
  setSharedMapInstanceRef,
  getSharedMapInstanceRef,
  getSharedMapCamera,
  applySharedMapCamera,
  easeInOutCubic,
} from './campusMapUtils';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import type { Map as MapboxMap } from 'mapbox-gl';

describe('campusMapUtils', () => {
  it('identifies coordinates within or outside campus', () => {
    expect(isWithinCampus(CAMPUS_CENTER)).toBe(true);
    expect(isWithinCampus([0, 0])).toBe(false);
    expect(isWithinCampus([CAMPUS_BOUNDS[0][0], CAMPUS_BOUNDS[0][1]])).toBe(true);
  });

  it('hashes strings consistently', () => {
    const h1 = hashString('building-1');
    const h2 = hashString('building-1');
    const h3 = hashString('building-2');
    expect(h1).toBe(h2);
    expect(h1).not.toBe(h3);
  });

  it('resolves building coordinates correctly', () => {
    const customBuilding: BuildingLocationDto = {
      id: 'b-1',
      name: 'Edificio A',
      location: { latitude: -38.73, longitude: -72.60 },
      isSuspended: false,
    };
    expect(resolveBuildingCoordinate(customBuilding)).toEqual([-72.60, -38.73]);

    const zeroCoordBuilding: BuildingLocationDto = {
      id: 'b-2',
      name: 'Edificio B',
      location: { latitude: 0, longitude: 0 },
      isSuspended: false,
    };
    const coord = resolveBuildingCoordinate(zeroCoordBuilding);
    expect(coord[0]).not.toBe(0);
    expect(coord[1]).not.toBe(0);
  });

  it('resolves structure coordinates correctly', () => {
    const customStructure: StructureDto = {
      id: 's-1',
      name: 'Estructura 1',
      latitude: -38.735,
      longitude: -72.605,
      categoryId: 'c-1',
      buildingId: 'b-1',
    };
    expect(resolveStructureCoordinate(customStructure)).toEqual([-72.605, -38.735]);

    const zeroCoordStructure: StructureDto = {
      id: 's-2',
      name: 'Estructura 2',
      latitude: 0,
      longitude: 0,
      categoryId: 'c-1',
      buildingId: 'b-1',
    };
    const coord = resolveStructureCoordinate(zeroCoordStructure);
    expect(coord[0]).not.toBe(0);
  });

  it('calculates easeInOutCubic', () => {
    expect(easeInOutCubic(0)).toBe(0);
    expect(easeInOutCubic(1)).toBe(1);
    expect(easeInOutCubic(0.5)).toBe(0.5);
  });

  it('calls flyToCoordinate with camera options', () => {
    const flyToMock = vi.fn();
    const mapMock = {
      flyTo: flyToMock,
      getZoom: () => 14,
      getPitch: () => 50,
      getBearing: () => -20,
    } as unknown as MapboxMap;

    flyToCoordinate(mapMock, [-72.6, -38.7], { zoom: 16 });
    expect(flyToMock).toHaveBeenCalledWith(
      expect.objectContaining({
        center: [-72.6, -38.7],
        zoom: 16,
        pitch: 50,
      }),
    );
  });

  it('handles shared map instance camera getters and setters', () => {
    setSharedMapInstanceRef(null);
    expect(getSharedMapInstanceRef()).toBeNull();
    expect(getSharedMapCamera()).toBeNull();

    const flyTo = vi.fn();
    const jumpTo = vi.fn();
    const mockMap = {
      getCenter: () => ({ lat: -38.7, lng: -72.6 }),
      getZoom: () => 15,
      getPitch: () => 45,
      getBearing: () => 10,
      flyTo,
      jumpTo,
    } as unknown as MapboxMap;

    setSharedMapInstanceRef(mockMap);
    expect(getSharedMapInstanceRef()).toBe(mockMap);

    const camera = getSharedMapCamera();
    expect(camera).toEqual({
      latitude: -38.7,
      longitude: -72.6,
      zoom: 15,
      pitch: 45,
      bearing: 10,
    });

    applySharedMapCamera(camera!, false);
    expect(jumpTo).toHaveBeenCalled();

    applySharedMapCamera(camera!, true);
    expect(flyTo).toHaveBeenCalled();

    setSharedMapInstanceRef(null);
  });
});
