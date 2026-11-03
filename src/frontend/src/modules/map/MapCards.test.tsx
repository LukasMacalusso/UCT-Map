import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { BaseDetailCard } from './BaseDetailCard';
import { BuildingDetailCard } from './BuildingDetailCard';
import { StructureDetailCard } from './StructureDetailCard';
import { ActiveBuildingCard } from './ActiveBuildingCard';
import { ActiveStructureCard } from './ActiveStructureCard';
import { ActiveEntityCard } from './ActiveEntityCard';
import { MapSidePanel } from './MapSidePanel';
import { RoomInfoCard } from './RoomInfoCard';
import { ScheduleCard } from './ScheduleCard';
import { BuildingStatCard } from './BuildingStatCard';
import { HeatmapSpot } from './HeatmapSpot';
import { MapFiltersPanel } from './MapFiltersPanel';
import { toBuildingMarker, toStructureMarker } from './mapAdapters';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import { Role } from '../../constants/role';

vi.mock('../../hooks/useCampus', () => ({
  useBuildingRooms: () => ({
    data: [{ id: 'r1', name: 'Sala 101', floor: 1, number: '101' }],
    isLoading: false,
  }),
  useCategories: () => ({
    data: [{ id: 'cat1', name: 'Baños' }],
    isLoading: false,
  }),
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'San Juan Pablo II' }],
    isLoading: false,
  }),
}));

vi.mock('../../states/authState', () => ({
  useAuthState: (selector: (s: unknown) => unknown) =>
    selector({
      user: { id: 'u1', name: 'Admin', role: Role.Admin },
      isAuthenticated: true,
    }),
}));

describe('Map Cards and Adapters', () => {
  it('mapAdapters converts building and structure to markers', () => {
    const b: BuildingLocationDto = {
      id: 'b1',
      name: 'Edificio A',
      location: { latitude: -38.7, longitude: -72.6 },
      isSuspended: false,
    };
    const bMarker = toBuildingMarker(b);
    expect(bMarker.id).toBe('b1');
    expect(bMarker.type).toBe('building');

    const s: StructureDto = {
      id: 's1',
      name: 'Estructura 1',
      latitude: -38.7,
      longitude: -72.6,
      categoryId: 'cat1',
      buildingId: 'b1',
    };
    const sMarker = toStructureMarker(s);
    expect(sMarker.id).toBe('s1');
    expect(sMarker.type).toBe('structure');
  });

  it('renders BaseDetailCard with actions', () => {
    const onReportProblem = vi.fn();
    const onReportLostObject = vi.fn();
    const onClose = vi.fn();

    renderWithQueryClient(
      <BaseDetailCard
        title="Edificio Central"
        subtitle="Campus San Juan"
        onClose={onClose}
        onReportProblem={onReportProblem}
        onReportLostObject={onReportLostObject}
      />,
    );

    expect(screen.getByText('Edificio Central')).toBeInTheDocument();
    expect(screen.getByText('Campus San Juan')).toBeInTheDocument();

    const problemBtn = screen.getByRole('button', { name: /reportar un problema/i });
    fireEvent.click(problemBtn);
    expect(onReportProblem).toHaveBeenCalled();

    const lostBtn = screen.getByRole('button', { name: /reportar objeto perdido/i });
    fireEvent.click(lostBtn);
    expect(onReportLostObject).toHaveBeenCalled();
  });

  it('renders BuildingDetailCard and StructureDetailCard', () => {
    renderWithQueryClient(
      <BuildingDetailCard
        title="Edificio A"
        rooms={[{ name: 'Sala 1', floor: 1, code: '101' }]}
      />,
    );
    expect(screen.getByText('Edificio A')).toBeInTheDocument();
    expect(screen.getByText('Sala 1')).toBeInTheDocument();

    renderWithQueryClient(
      <StructureDetailCard title="Punto de reciclaje" subtitle="Exterior" />,
    );
    expect(screen.getByText('Punto de reciclaje')).toBeInTheDocument();
  });

  it('renders ActiveBuildingCard, ActiveStructureCard and ActiveEntityCard', () => {
    const b: BuildingLocationDto = {
      id: 'b1',
      name: 'Edificio B',
      location: { latitude: 0, longitude: 0 },
      isSuspended: false,
    };
    renderWithQueryClient(<ActiveBuildingCard building={b} onClose={vi.fn()} />);
    expect(screen.getByText('Edificio B')).toBeInTheDocument();

    const s: StructureDto = {
      id: 's1',
      name: 'Casino',
      latitude: 0,
      longitude: 0,
      categoryId: 'cat1',
      buildingId: 'b1',
    };
    renderWithQueryClient(<ActiveStructureCard structure={s} onClose={vi.fn()} />);
    expect(screen.getByText('Casino')).toBeInTheDocument();

    renderWithQueryClient(
      <ActiveEntityCard
        marker={{ id: 'b1', type: 'building', data: b }}
        onClose={vi.fn()}
      />,
    );
    expect(screen.getAllByText('Edificio B').length).toBeGreaterThan(0);
  });

  it('renders RoomInfoCard, ScheduleCard, BuildingStatCard, HeatmapSpot', () => {
    renderWithQueryClient(<RoomInfoCard title="Laboratorio 1" type="Laboratorio" capacity={30} />);
    expect(screen.getByText('Laboratorio 1')).toBeInTheDocument();

    renderWithQueryClient(<ScheduleCard schedule="08:00 - 20:00" />);
    expect(screen.getByText('08:00 - 20:00')).toBeInTheDocument();

    renderWithQueryClient(<BuildingStatCard icon={<span>icon</span>} label="Aforo" value="50 personas" />);
    expect(screen.getByText('50 personas')).toBeInTheDocument();

    renderWithQueryClient(<HeatmapSpot intensity="high" />);
    expect(document.querySelector('.rounded-full')).toBeInTheDocument();
  });

  it('renders MapSidePanel and MapFiltersPanel and handles interactions', () => {
    const onClose = vi.fn();
    renderWithQueryClient(<MapSidePanel onClose={onClose} />);
    expect(screen.getByText('Filtros')).toBeInTheDocument();
    expect(screen.getByText('Baños')).toBeInTheDocument();

    const banosCheckbox = screen.getByLabelText(/baños/i);
    fireEvent.click(banosCheckbox);

    const clearBtn = screen.getByText(/limpiar \(1\)/i);
    expect(clearBtn).toBeInTheDocument();
    fireEvent.click(clearBtn);

    const closeBtn = screen.getByRole('button', { name: /cerrar/i });
    fireEvent.click(closeBtn);
    expect(onClose).toHaveBeenCalled();

    renderWithQueryClient(
      <MapFiltersPanel
        sections={[
          {
            title: 'Filtros Secundarios',
            items: [{ id: 'f1', label: 'Salas', checked: true, onChange: vi.fn() }],
          },
        ]}
      />,
    );
    expect(screen.getByText('Salas')).toBeInTheDocument();
  });
});
