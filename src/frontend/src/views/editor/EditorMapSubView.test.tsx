import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import type { ReactNode } from 'react';
import { EditorMapSubView } from './EditorMapSubView';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';

const mocks = vi.hoisted(() => ({
  createBuilding: vi.fn(),
  updateBuilding: vi.fn(),
  updateBuildingLocation: vi.fn(),
  deleteBuilding: vi.fn(),
  createStructure: vi.fn(),
  updateStructure: vi.fn(),
  updateStructureLocation: vi.fn(),
  deleteStructure: vi.fn(),
}));

vi.mock('../../hooks/useCampus', () => ({
  useCampuses: () => ({ data: [{ id: 'c1', name: 'Campus 1' }] }),
  useCategories: () => ({ data: [{ id: 'cat1', name: 'Cat 1' }] }),
  useCreateBuilding: () => ({
    mutate: mocks.createBuilding,
    isPending: false,
    isError: false,
    error: null,
  }),
  useUpdateBuilding: () => ({
    mutate: mocks.updateBuilding,
    isPending: false,
    isError: false,
    error: null,
  }),
  useUpdateBuildingLocation: () => ({
    mutate: mocks.updateBuildingLocation,
    isPending: false,
    isError: false,
    error: null,
  }),
  useDeleteBuilding: () => ({
    mutate: mocks.deleteBuilding,
    isPending: false,
    isError: false,
    error: null,
  }),
  useCreateStructure: () => ({
    mutate: mocks.createStructure,
    isPending: false,
    isError: false,
    error: null,
  }),
  useUpdateStructure: () => ({
    mutate: mocks.updateStructure,
    isPending: false,
    isError: false,
    error: null,
  }),
  useUpdateStructureLocation: () => ({
    mutate: mocks.updateStructureLocation,
    isPending: false,
    isError: false,
    error: null,
  }),
  useDeleteStructure: () => ({
    mutate: mocks.deleteStructure,
    isPending: false,
    isError: false,
    error: null,
  }),
}));

vi.mock('./EditorMapCanvas', () => ({
  EditorMapCanvas: ({
    children,
    topMessage,
    onMapClick,
    onMarkerClick,
    onMarkerDragEnd,
    onCampusChange,
  }: {
    children?: ReactNode;
    topMessage?: ReactNode;
    onMapClick?: (coords: [number, number]) => void;
    onMarkerClick?: (marker: MapMarkerItem) => void;
    onMarkerDragEnd?: (marker: MapMarkerItem, coords: [number, number]) => void;
    onCampusChange?: (campusId: string) => void;
  }) => {
    const buildingMarker: MapMarkerItem = {
      id: 'b1',
      name: 'Edificio Mock',
      type: 'building',
      coordinates: [-72.6, -38.7],
      data: {
        id: 'b1',
        name: 'Edificio Mock',
        location: { latitude: -38.7, longitude: -72.6 },
        metadata: { campusId: 'c1', floorsCount: 2, schedule: '08:00 - 18:00' },
      },
    };

    const structureMarker: MapMarkerItem = {
      id: 's1',
      name: 'Estructura Mock',
      type: 'structure',
      coordinates: [-72.61, -38.71],
      data: {
        id: 's1',
        campusId: 'c1',
        categoryId: 'cat1',
        name: 'Estructura Mock',
        latitude: -38.71,
        longitude: -72.61,
      },
    };

    return (
      <div>
        {topMessage}
        <button type="button" onClick={() => onMapClick?.([-72.6, -38.7])}>
          mock-map-click
        </button>
        <button type="button" onClick={() => onMarkerClick?.(buildingMarker)}>
          mock-building-click
        </button>
        <button type="button" onClick={() => onMarkerClick?.(structureMarker)}>
          mock-structure-click
        </button>
        <button type="button" onClick={() => onMarkerDragEnd?.(buildingMarker, [-72.62, -38.72])}>
          mock-building-drag
        </button>
        <button type="button" onClick={() => onMarkerDragEnd?.(structureMarker, [-72.63, -38.73])}>
          mock-structure-drag
        </button>
        <button type="button" onClick={() => onCampusChange?.('c2')}>
          mock-campus-change
        </button>
        {children}
      </div>
    );
  },
}));

const LocationProbe = () => {
  const location = useLocation();
  return <div data-testid="location">{`${location.pathname}${location.search}`}</div>;
};

const renderView = () =>
  renderWithQueryClient(
    <MemoryRouter>
      <EditorMapSubView />
      <LocationProbe />
    </MemoryRouter>,
  );

describe('EditorMapSubView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('creates a building from a map click', () => {
    renderView();

    fireEvent.click(screen.getByTitle('Añadir marcador'));
    fireEvent.click(screen.getByText('mock-map-click'));

    expect(screen.getByText('Nuevo Marcador en el Mapa')).toBeInTheDocument();
    expect(screen.getByText(/Coordenadas seleccionadas/i)).toBeInTheDocument();

    fireEvent.change(
      screen.getByPlaceholderText('Ej: Pabellón C, Edificio San Francisco'),
      { target: { value: 'Edificio Nuevo' } },
    );
    fireEvent.change(screen.getByRole('spinbutton'), { target: { value: '3' } });

    fireEvent.click(screen.getByRole('button', { name: /crear marcador/i }));

    expect(mocks.createBuilding).toHaveBeenCalledWith(
      expect.objectContaining({
        campusId: 'c1',
        name: 'Edificio Nuevo',
        floorsCount: 3,
      }),
      expect.any(Object),
    );
  });

  it('creates a structure from a map click', () => {
    renderView();

    fireEvent.click(screen.getByTitle('Añadir marcador'));
    fireEvent.click(screen.getByText('mock-map-click'));

    fireEvent.click(screen.getByRole('button', { name: /estructura/i }));
    fireEvent.change(
      screen.getByPlaceholderText('Ej: Cancha de Fútbol, Quincho, Estacionamiento Central'),
      { target: { value: 'Cancha Nueva' } },
    );

    fireEvent.click(screen.getByRole('button', { name: /crear marcador/i }));

    expect(mocks.createStructure).toHaveBeenCalledWith(
      expect.objectContaining({
        campusId: 'c1',
        name: 'Cancha Nueva',
        categoryId: 'cat1',
      }),
      expect.any(Object),
    );
  });

  it('updates building and structure positions on drag end', () => {
    renderView();

    fireEvent.click(screen.getByTitle('Mover marcador en el mapa'));
    fireEvent.click(screen.getByText('mock-building-drag'));

    expect(mocks.updateBuildingLocation).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 'b1',
        latitude: -38.72,
        longitude: -72.62,
      }),
      expect.any(Object),
    );

    fireEvent.click(screen.getByText('mock-structure-drag'));

    expect(mocks.updateStructureLocation).toHaveBeenCalledWith(
      expect.objectContaining({
        id: 's1',
        latitude: -38.73,
        longitude: -72.63,
      }),
      expect.any(Object),
    );
  });

  it('deletes a building and a structure after confirmation', () => {
    renderView();

    vi.useFakeTimers();
    fireEvent.click(screen.getByText('mock-building-click'));
    fireEvent.click(screen.getByTitle('Eliminar marcador'));

    expect(screen.getByText('Eliminar edificio')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(1600);
    });

    fireEvent.click(screen.getByText('Sí, eliminar'));
    expect(mocks.deleteBuilding).toHaveBeenCalledWith('b1', expect.any(Object));

    fireEvent.click(screen.getByRole('button', { name: /cancelar/i }));
    fireEvent.click(screen.getByText('mock-structure-click'));
    fireEvent.click(screen.getByTitle('Eliminar marcador'));

    expect(screen.getByText('Eliminar estructura')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(1600);
    });

    fireEvent.click(screen.getByText('Sí, eliminar'));
    expect(mocks.deleteStructure).toHaveBeenCalledWith('s1', expect.any(Object));
    vi.useRealTimers();
  });

  it('navigates to the building editor in inspect mode', () => {
    renderView();

    fireEvent.click(screen.getByText('mock-structure-click'));
    fireEvent.click(screen.getByTitle('Editar detalles del elemento'));

    expect(screen.getByTestId('location')).toHaveTextContent(
      '/edition/buildings?id=s1&type=structure',
    );
  });

  it('closes active tools and modals with Escape', () => {
    renderView();

    fireEvent.click(screen.getByTitle('Añadir marcador'));
    fireEvent.click(screen.getByText('mock-map-click'));
    expect(screen.getByText('Nuevo Marcador en el Mapa')).toBeInTheDocument();

    fireEvent.keyDown(window, { key: 'Escape' });

    expect(screen.queryByText('Nuevo Marcador en el Mapa')).not.toBeInTheDocument();
    expect(
      screen.queryByText(/Haz clic en el mapa para ubicar un nuevo marcador/i),
    ).not.toBeInTheDocument();
  });

  it('changes the active campus and keeps the create flow working', () => {
    renderView();

    fireEvent.click(screen.getByText('mock-campus-change'));
    fireEvent.click(screen.getByTitle('Añadir marcador'));
    fireEvent.click(screen.getByText('mock-map-click'));

    expect(screen.getByText('Nuevo Marcador en el Mapa')).toBeInTheDocument();
  });
});
