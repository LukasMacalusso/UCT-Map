import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { MapView } from './MapView';
import { MapEditorView } from './MapEditorView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';

const campusState = vi.hoisted(() => ({
  campuses: [{ id: 'c1', name: 'Campus San Juan' }] as Record<string, unknown>[],
  buildings: [
    {
      id: 'b1',
      name: 'Edificio Central',
      location: { latitude: 0, longitude: 0 },
      isSuspended: false,
    },
  ] as Record<string, unknown>[] | undefined,
  structures: [
    {
      id: 's1',
      name: 'Casino',
      latitude: 0,
      longitude: 0,
      categoryId: 'cat1',
      buildingId: 'b1',
      campusId: 'c1',
    },
  ] as Record<string, unknown>[] | undefined,
}));

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: campusState.campuses,
    isLoading: false,
  }),
  useBuildingLocations: () => ({
    data: campusState.buildings,
    isLoading: false,
  }),
  useStructures: () => ({
    data: campusState.structures,
    isLoading: false,
  }),
  useBuildingRooms: () => ({
    data: [{ id: 'r1', name: 'Sala 101', floor: 1, number: '101' }],
    isLoading: false,
  }),
  useCategories: () => ({
    data: [],
    isLoading: false,
  }),
}));

vi.mock('../states/authState', () => ({
  useAuthState: (selector: (s: unknown) => unknown) =>
    selector({
      user: { id: 'u1', name: 'Admin', role: 'Admin' },
      isAuthenticated: true,
    }),
}));

const renderMap = (extraRoutes = false) =>
  renderWithQueryClient(
    <MemoryRouter initialEntries={['/map']}>
      <Routes>
        <Route path="/map" element={<MapView />} />
        {extraRoutes && (
          <>
            <Route path="/reports" element={<div>Página Reportes</div>} />
            <Route path="/objects" element={<div>Página Objetos</div>} />
          </>
        )}
      </Routes>
    </MemoryRouter>,
  );

const selectMarker = (query: string, label: RegExp) => {
  const searchInput = screen.getByPlaceholderText(/buscar edificio/i);
  fireEvent.focus(searchInput);
  fireEvent.change(searchInput, { target: { value: query } });
  fireEvent.click(screen.getByText(label));
};

describe('Map Views', () => {
  beforeEach(() => {
    campusState.campuses = [{ id: 'c1', name: 'Campus San Juan' }];
    campusState.buildings = [
      {
        id: 'b1',
        name: 'Edificio Central',
        location: { latitude: 0, longitude: 0 },
        isSuspended: false,
      },
    ];
    campusState.structures = [
      {
        id: 's1',
        name: 'Casino',
        latitude: 0,
        longitude: 0,
        categoryId: 'cat1',
        buildingId: 'b1',
        campusId: 'c1',
      },
    ];
  });

  it('renders MapView with campus selector, search, side panel and marker interactions', () => {
    renderMap(true);

    expect(screen.getAllByText('Campus San Juan').length).toBeGreaterThan(0);

    // Toggle side panel
    const openPanelBtn = screen.getByTitle('Abrir panel');
    fireEvent.click(openPanelBtn);
    expect(screen.getByTitle('Cerrar panel')).toBeInTheDocument();

    // Select marker via search input
    selectMarker('Central', /Edificio Central \(Edificio\)/i);

    expect(screen.getAllByText('Edificio Central').length).toBeGreaterThan(0);

    // Navigate and view 360 actions inside ActiveEntityCard
    fireEvent.click(screen.getByRole('button', { name: /llegar/i }));
    fireEvent.click(screen.getByRole('button', { name: /360/i }));

    // Click Report Problem inside ActiveEntityCard
    const reportBtn = screen.getByRole('button', { name: /reportar un problema/i });
    fireEvent.click(reportBtn);

    expect(screen.getByText('Página Reportes')).toBeInTheDocument();
  });

  it('handles report lost object navigation and closing detail card in MapView', () => {
    vi.useFakeTimers();
    renderMap(true);

    selectMarker('Central', /Edificio Central \(Edificio\)/i);

    // Click Report Lost Object
    const lostBtn = screen.getByRole('button', { name: /reportar objeto perdido/i });
    fireEvent.click(lostBtn);

    expect(screen.getByText('Página Objetos')).toBeInTheDocument();
    vi.useRealTimers();
  });

  it('navigates from a structure marker to reports and objects', () => {
    const reports = renderMap(true);
    selectMarker('Casino', /Casino \(Estructura\)/i);

    fireEvent.click(screen.getByRole('button', { name: /reportar un problema/i }));
    expect(screen.getByText('Página Reportes')).toBeInTheDocument();
    reports.unmount();

    renderMap(true);
    selectMarker('Casino', /Casino \(Estructura\)/i);
    fireEvent.click(screen.getByRole('button', { name: /reportar objeto perdido/i }));
    expect(screen.getByText('Página Objetos')).toBeInTheDocument();
  });

  it('clears a pending close timeout when another marker is selected', () => {
    vi.useFakeTimers();
    renderMap();

    selectMarker('Central', /Edificio Central \(Edificio\)/i);
    fireEvent.click(screen.getAllByRole('button', { name: 'Cerrar' }).at(-1)!);

    selectMarker('Casino', /Casino \(Estructura\)/i);
    act(() => {
      vi.advanceTimersByTime(600);
    });

    expect(screen.getAllByText('Casino').length).toBeGreaterThan(0);
    vi.useRealTimers();
  });

  it('renders with empty campus and marker data', () => {
    campusState.campuses = [];
    campusState.buildings = undefined;
    campusState.structures = undefined;

    renderMap();

    expect(screen.getByTitle('Abrir panel')).toBeInTheDocument();
    expect(screen.queryByText('Campus San Juan')).not.toBeInTheDocument();
  });

  it('renders MapEditorView navigation bar and links', () => {
    renderWithQueryClient(
      <MemoryRouter initialEntries={['/edition/map']}>
        <Routes>
          <Route path="/edition" element={<MapEditorView />}>
            <Route path="map" element={<div>Editor Subview Map</div>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    );

    expect(screen.getByText('MAPA')).toBeInTheDocument();
    expect(screen.getByText('CAMPUS')).toBeInTheDocument();
    expect(screen.getByText('EDIFICIOS')).toBeInTheDocument();
    expect(screen.getByText('FILTROS')).toBeInTheDocument();
    expect(screen.getByText('Editor Subview Map')).toBeInTheDocument();
  });
});
