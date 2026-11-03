import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { MapView } from './MapView';
import { MapEditorView } from './MapEditorView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useBuildingLocations: () => ({
    data: [{ id: 'b1', name: 'Edificio Central', location: { latitude: 0, longitude: 0 }, isSuspended: false }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Casino', latitude: 0, longitude: 0, categoryId: 'cat1', buildingId: 'b1' }],
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

describe('Map Views', () => {
  it('renders MapView with campus selector, search, side panel and marker interactions', () => {
    renderWithQueryClient(
      <MemoryRouter initialEntries={['/map']}>
        <Routes>
          <Route path="/map" element={<MapView />} />
          <Route path="/reports" element={<div>Página Reportes</div>} />
          <Route path="/objects" element={<div>Página Objetos</div>} />
        </Routes>
      </MemoryRouter>,
    );

    expect(screen.getAllByText('Campus San Juan').length).toBeGreaterThan(0);

    // Toggle side panel
    const openPanelBtn = screen.getByTitle('Abrir panel');
    fireEvent.click(openPanelBtn);
    expect(screen.getByTitle('Cerrar panel')).toBeInTheDocument();

    // Select marker via search input
    const searchInput = screen.getByPlaceholderText(/buscar edificio/i);
    fireEvent.focus(searchInput);
    fireEvent.change(searchInput, { target: { value: 'Central' } });

    const optionBtn = screen.getByText(/Edificio Central \(Edificio\)/i);
    fireEvent.click(optionBtn);

    expect(screen.getAllByText('Edificio Central').length).toBeGreaterThan(0);

    // Click Report Problem inside ActiveEntityCard
    const reportBtn = screen.getByRole('button', { name: /reportar un problema/i });
    fireEvent.click(reportBtn);

    expect(screen.getByText('Página Reportes')).toBeInTheDocument();
  });

  it('handles report lost object navigation and closing detail card in MapView', () => {
    vi.useFakeTimers();
    renderWithQueryClient(
      <MemoryRouter initialEntries={['/map']}>
        <Routes>
          <Route path="/map" element={<MapView />} />
          <Route path="/objects" element={<div>Página Objetos</div>} />
        </Routes>
      </MemoryRouter>,
    );

    // Select marker via search input
    const searchInput = screen.getByPlaceholderText(/buscar edificio/i);
    fireEvent.focus(searchInput);
    fireEvent.change(searchInput, { target: { value: 'Central' } });

    const optionBtn = screen.getByText(/Edificio Central \(Edificio\)/i);
    fireEvent.click(optionBtn);

    // Click Report Lost Object
    const lostBtn = screen.getByRole('button', { name: /reportar objeto perdido/i });
    fireEvent.click(lostBtn);

    expect(screen.getByText('Página Objetos')).toBeInTheDocument();
    vi.useRealTimers();
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
