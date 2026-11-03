import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { CampusCameraInfo } from './CampusCameraInfo';
import { EditorMapCanvas } from './EditorMapCanvas';
import { EditorFiltersSubView } from './EditorFiltersSubView';
import { EditorCampusSubView } from './EditorCampusSubView';
import { EditorMapSubView } from './EditorMapSubView';
import { EditorBuildingsSubView } from './EditorBuildingsSubView';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';

const mockCreateCampus = vi.fn();
const mockUpdateCampus = vi.fn();
const mockDeleteCampus = vi.fn();
const mockCreateCategory = vi.fn();
const mockUpdateCategory = vi.fn();
const mockDeleteCategory = vi.fn();
const mockReorderCategories = vi.fn();
const mockCreateBuilding = vi.fn();
const mockUpdateBuilding = vi.fn();
const mockUpdateBuildingLocation = vi.fn();
const mockDeleteBuilding = vi.fn();
const mockCreateStructure = vi.fn();
const mockUpdateStructure = vi.fn();
const mockUpdateStructureLocation = vi.fn();
const mockDeleteStructure = vi.fn();
const mockCreateRoom = vi.fn();
const mockUpdateRoom = vi.fn();
const mockDeleteRoom = vi.fn();

vi.mock('../../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [
      {
        id: 'c1',
        name: 'Campus San Juan Pablo II',
        address: 'Rudecindo Ortega 02950',
        latitude: -38.706,
        longitude: -72.585,
        zoom: 17,
        pitch: 45,
        bearing: 10,
        metadata: {
          camera: {
            latitude: -38.706,
            longitude: -72.585,
            zoom: 17,
            pitch: 45,
            bearing: 10,
          },
        },
      },
    ],
    isLoading: false,
  }),
  useCreateCampus: () => ({ mutate: mockCreateCampus, isPending: false }),
  useUpdateCampus: () => ({ mutate: mockUpdateCampus, isPending: false }),
  useDeleteCampus: () => ({ mutate: mockDeleteCampus, isPending: false }),

  useBuildingLocations: () => ({
    data: [
      {
        id: 'b1',
        name: 'Edificio Central',
        location: { latitude: -38.706, longitude: -72.585 },
        isSuspended: false,
        campusId: 'c1',
        metadata: { campusId: 'c1', floorsCount: 4, schedule: '08:00 - 20:00' },
      },
    ],
    isLoading: false,
  }),
  useCreateBuilding: () => ({ mutate: mockCreateBuilding, isPending: false }),
  useUpdateBuilding: () => ({ mutate: mockUpdateBuilding, isPending: false }),
  useUpdateBuildingLocation: () => ({ mutate: mockUpdateBuildingLocation, isPending: false }),
  useDeleteBuilding: () => ({ mutate: mockDeleteBuilding, isPending: false }),
  useSetBuildingLocation: () => ({ mutate: vi.fn(), isPending: false }),

  useStructures: () => ({
    data: [
      {
        id: 's1',
        name: 'Casino Central',
        latitude: -38.707,
        longitude: -72.586,
        categoryId: 'cat1',
        buildingId: 'b1',
        campusId: 'c1',
      },
    ],
    isLoading: false,
  }),
  useCreateStructure: () => ({ mutate: mockCreateStructure, isPending: false }),
  useUpdateStructure: () => ({ mutate: mockUpdateStructure, isPending: false }),
  useUpdateStructureLocation: () => ({ mutate: mockUpdateStructureLocation, isPending: false }),
  useDeleteStructure: () => ({ mutate: mockDeleteStructure, isPending: false }),
  useSetStructureLocation: () => ({ mutate: vi.fn(), isPending: false }),

  useCategories: () => ({
    data: [
      {
        id: 'cat1',
        name: 'Alimentación',
        description: 'Casinos y cafeterías',
        icon: 'coffee',
        order: 1,
      },
      {
        id: 'cat2',
        name: 'Estudio',
        description: 'Salas de estudio',
        icon: 'study',
        order: 2,
      },
    ],
    isLoading: false,
  }),
  useCreateCategory: () => ({ mutate: mockCreateCategory, isPending: false }),
  useUpdateCategory: () => ({ mutate: mockUpdateCategory, isPending: false }),
  useDeleteCategory: () => ({ mutate: mockDeleteCategory, isPending: false }),
  useReorderCategories: () => ({ mutate: mockReorderCategories, isPending: false }),

  useBuildingRooms: () => ({
    data: [
      {
        id: 'r1',
        name: 'Laboratorio de Software',
        number: 'L1',
        floor: 1,
        buildingId: 'b1',
        categoryId: 'cat2',
      },
    ],
    isLoading: false,
  }),
  useCreateRoom: () => ({ mutate: mockCreateRoom, isPending: false }),
  useUpdateRoom: () => ({ mutate: mockUpdateRoom, isPending: false }),
  useDeleteRoom: () => ({ mutate: mockDeleteRoom, isPending: false }),
}));

vi.mock('../../modules/map/campusMapUtils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../modules/map/campusMapUtils')>();
  return {
    ...actual,
    getSharedMapCamera: () => ({
      latitude: -38.7,
      longitude: -72.6,
      zoom: 15,
      pitch: 0,
      bearing: 0,
    }),
  };
});

describe('Editor SubViews', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('CampusCameraInfo', () => {
    it('renders camera parameters correctly formatted', () => {
      renderWithQueryClient(
        <CampusCameraInfo
          camera={{
            latitude: -38.70612,
            longitude: -72.58543,
            zoom: 17.5,
            pitch: 45.0,
            bearing: 10.2,
          }}
        />,
      );

      expect(screen.getByText('-38.70612')).toBeInTheDocument();
      expect(screen.getByText('-72.58543')).toBeInTheDocument();
      expect(screen.getByText('17.50x')).toBeInTheDocument();
      expect(screen.getByText('45.0°')).toBeInTheDocument();
      expect(screen.getByText('10.2°')).toBeInTheDocument();
    });
  });

  describe('EditorMapCanvas', () => {
    it('renders with children and campus selector', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorMapCanvas campusId="c1" topMessage={<span>Modo Edición Activo</span>}>
            <div>Overlay Content</div>
          </EditorMapCanvas>
        </MemoryRouter>,
      );

      expect(screen.getByText('Modo Edición Activo')).toBeInTheDocument();
      expect(screen.getByText('Overlay Content')).toBeInTheDocument();
      expect(screen.getAllByText('Campus San Juan Pablo II').length).toBeGreaterThan(0);
    });
  });

  describe('EditorFiltersSubView', () => {
    it('renders categories list, switches to create mode, and saves', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorFiltersSubView />
        </MemoryRouter>,
      );

      expect(screen.getByText('Filtros del mapa')).toBeInTheDocument();
      expect(screen.getByText('Alimentación')).toBeInTheDocument();
      expect(screen.getByText('Estudio')).toBeInTheDocument();

      const newBtn = screen.getByRole('button', { name: /nuevo filtro/i });
      fireEvent.click(newBtn);

      expect(screen.getByPlaceholderText('Ej: Laboratorio, Baños, Biblioteca')).toBeInTheDocument();

      const nameInput = screen.getByPlaceholderText('Ej: Laboratorio, Baños, Biblioteca');
      fireEvent.change(nameInput, { target: { value: 'Laboratorios' } });

      const descInput = screen.getByPlaceholderText('Descripción breve de la categoría');
      fireEvent.change(descInput, { target: { value: 'Salas de cómputo' } });

      const saveBtn = screen.getByRole('button', { name: /guardar filtro/i });
      fireEvent.click(saveBtn);

      expect(mockCreateCategory).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Laboratorios',
          description: 'Salas de cómputo',
        }),
        expect.any(Object),
      );
    });

    it('switches to edit mode for an existing category', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorFiltersSubView />
        </MemoryRouter>,
      );

      const editButtons = screen.getAllByTitle('Editar filtro');
      fireEvent.click(editButtons[0]);

      expect(screen.getByText('Editar filtro')).toBeInTheDocument();

      const cancelBtn = screen.getByRole('button', { name: /cancelar/i });
      fireEvent.click(cancelBtn);

      expect(screen.getByText('Filtros del mapa')).toBeInTheDocument();
    });

    it('saves changes when editing an existing filter', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorFiltersSubView />
        </MemoryRouter>,
      );

      fireEvent.click(screen.getAllByTitle('Editar filtro')[0]);

      const nameInput = screen.getByDisplayValue('Alimentación');
      fireEvent.change(nameInput, { target: { value: 'Comida' } });

      const iconSelect = screen.getByRole('combobox');
      fireEvent.change(iconSelect, { target: { value: 'computer' } });

      fireEvent.click(screen.getByRole('button', { name: /guardar filtro/i }));

      expect(mockUpdateCategory).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'cat1',
          payload: expect.objectContaining({
            name: 'Comida',
            icon: 'computer',
          }),
        }),
        expect.any(Object),
      );
    });

    it('deletes a filter after the confirmation timer', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorFiltersSubView />
        </MemoryRouter>,
      );

      vi.useFakeTimers();
      fireEvent.click(screen.getAllByTitle('Eliminar filtro')[0]);

      expect(screen.getByText('Eliminar filtro')).toBeInTheDocument();

      act(() => {
        vi.advanceTimersByTime(1600);
      });

      fireEvent.click(screen.getByText('Sí, eliminar'));

      expect(mockDeleteCategory).toHaveBeenCalledWith('cat1', expect.any(Object));
      vi.useRealTimers();
    });

    it('reorders filters with drag and drop', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorFiltersSubView />
        </MemoryRouter>,
      );

      const source = screen.getByText('Alimentación').closest('[draggable="true"]');
      const target = screen.getByText('Estudio').closest('[draggable="true"]');
      const dataTransfer = { setData: vi.fn(), effectAllowed: '' };

      fireEvent.dragStart(source!, { dataTransfer });
      fireEvent.dragOver(target!, { dataTransfer, clientY: 0 });
      fireEvent.drop(target!, { dataTransfer });

      expect(mockReorderCategories).toHaveBeenCalledWith([
        { id: 'cat2', order: 1 },
        { id: 'cat1', order: 2 },
      ]);
    });
  });

  describe('EditorCampusSubView', () => {
    it('renders campuses list and allows switching to create mode', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorCampusSubView />
        </MemoryRouter>,
      );

      expect(screen.getAllByText('Campus San Juan Pablo II').length).toBeGreaterThan(0);

      const newBtn = screen.getByRole('button', { name: /crear nuevo campus/i });
      fireEvent.click(newBtn);

      expect(screen.getByText('Nuevo campus')).toBeInTheDocument();
      const nameInput = screen.getByPlaceholderText('Nombre del campus');
      fireEvent.change(nameInput, { target: { value: 'Campus Norte' } });

      const addressInput = screen.getByPlaceholderText('Dirección del campus');
      fireEvent.change(addressInput, { target: { value: 'Av. Norte 123' } });

      const cancelBtn = screen.getByTitle('Volver a la lista');
      fireEvent.click(cancelBtn);

      expect(screen.getByText('Campus')).toBeInTheDocument();
    });

    it('opens edit mode for a selected campus and saves', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorCampusSubView />
        </MemoryRouter>,
      );

      const editBtn = screen.getByTitle('Editar campus');
      fireEvent.click(editBtn);

      expect(screen.getByText('Editar campus')).toBeInTheDocument();

      const nameInput = screen.getByPlaceholderText('Nombre del campus');
      fireEvent.change(nameInput, { target: { value: 'Campus San Juan Actualizado' } });

      const saveBtn = screen.getByRole('button', { name: /guardar cambios/i });
      fireEvent.click(saveBtn);

      expect(mockUpdateCampus).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'c1',
          payload: expect.objectContaining({
            name: 'Campus San Juan Actualizado',
          }),
        }),
        expect.any(Object),
      );
    });

    it('creates a campus when the form is complete', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorCampusSubView />
        </MemoryRouter>,
      );

      fireEvent.click(screen.getByRole('button', { name: /crear nuevo campus/i }));

      fireEvent.change(screen.getByPlaceholderText('Nombre del campus'), {
        target: { value: 'Campus Norte' },
      });
      fireEvent.change(screen.getByPlaceholderText('Dirección del campus'), {
        target: { value: 'Av. Norte 123' },
      });

      fireEvent.click(screen.getByRole('button', { name: /crear campus/i }));

      expect(mockCreateCampus).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Campus Norte',
          address: 'Av. Norte 123',
        }),
        expect.any(Object),
      );
    });

    it('shows the associated entities warning when deleting a campus', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorCampusSubView />
        </MemoryRouter>,
      );

      vi.useFakeTimers();
      fireEvent.click(screen.getByTitle('Editar campus'));
      fireEvent.click(screen.getByRole('button', { name: /eliminar este campus/i }));

      expect(
        screen.getByText(/tiene 1 edificio y 1 estructura asociada/i),
      ).toBeInTheDocument();

      act(() => {
        vi.advanceTimersByTime(50);
      });

      fireEvent.click(screen.getByRole('button', { name: /entendido/i }));

      expect(
        screen.queryByText(/tiene 1 edificio y 1 estructura asociada/i),
      ).not.toBeInTheDocument();
      vi.useRealTimers();
    });
  });

  describe('EditorMapSubView', () => {
    it('renders editor map subview and toggles tool buttons', () => {
      renderWithQueryClient(
        <MemoryRouter>
          <EditorMapSubView />
        </MemoryRouter>,
      );

      const addBtn = screen.getByTitle('Añadir marcador');
      expect(addBtn).toBeInTheDocument();
      fireEvent.click(addBtn);

      expect(screen.getByText(/Haz clic en el mapa para ubicar un nuevo marcador/i)).toBeInTheDocument();

      const cancelBtn = screen.getByRole('button', { name: /cancelar/i });
      fireEvent.click(cancelBtn);
    });
  });

  describe('EditorBuildingsSubView', () => {
    it('renders buildings and structures list, selects an item and views details', () => {
      renderWithQueryClient(
        <MemoryRouter initialEntries={['/edition/buildings?id=b1&type=building']}>
          <EditorBuildingsSubView />
        </MemoryRouter>,
      );

      expect(screen.getByText(/Lista \(/i)).toBeInTheDocument();
      expect(screen.getAllByText('Edificio Central').length).toBeGreaterThan(0);
      expect(screen.getByText('Editar edificio')).toBeInTheDocument();
      expect(screen.getByText('Laboratorio de Software')).toBeInTheDocument();

      // Open Edit Building modal
      const editBuildingBtn = screen.getByRole('button', { name: /editar edificio/i });
      fireEvent.click(editBuildingBtn);

      expect(screen.getAllByText('Editar edificio').length).toBeGreaterThan(1);
      const cancelEditBuildingBtn = screen.getAllByRole('button', { name: /cancelar/i })[0];
      fireEvent.click(cancelEditBuildingBtn);

      // Open Add Room modal and create room
      const addRoomBtn = screen.getByRole('button', { name: /añadir sala/i });
      fireEvent.click(addRoomBtn);

      expect(screen.getByText('Añadir nueva sala')).toBeInTheDocument();

      const roomNameInput = screen.getByPlaceholderText('Ej: Sala 101, Lab de Computación');
      fireEvent.change(roomNameInput, { target: { value: 'Sala 201' } });

      const createRoomBtn = screen.getByRole('button', { name: /crear sala/i });
      fireEvent.click(createRoomBtn);
      expect(mockCreateRoom).toHaveBeenCalled();

      // Edit Room
      const editRoomBtn = screen.getByTitle('Editar sala');
      fireEvent.click(editRoomBtn);
      expect(screen.getByText('Editar sala')).toBeInTheDocument();

      const saveEditRoomBtn = screen.getByRole('button', { name: /guardar cambios/i });
      fireEvent.click(saveEditRoomBtn);
      expect(mockUpdateRoom).toHaveBeenCalled();

      // Delete Room
      vi.useFakeTimers();
      const deleteRoomBtn = screen.getByTitle('Eliminar sala');
      fireEvent.click(deleteRoomBtn);
      expect(screen.getByText('Eliminar sala')).toBeInTheDocument();

      act(() => {
        vi.advanceTimersByTime(1600);
      });

      const confirmDeleteRoomBtn = screen.getByText('Sí, eliminar');
      fireEvent.click(confirmDeleteRoomBtn);
      expect(mockDeleteRoom).toHaveBeenCalled();
      vi.useRealTimers();

      // Floor tab click
      const floor1Btn = screen.getByRole('button', { name: /piso 1/i });
      fireEvent.click(floor1Btn);
    });

    it('renders structure details and opens edit structure modal', () => {
      renderWithQueryClient(
        <MemoryRouter initialEntries={['/edition/buildings?id=s1&type=structure']}>
          <EditorBuildingsSubView />
        </MemoryRouter>,
      );

      expect(screen.getAllByText('Casino Central').length).toBeGreaterThan(0);
      expect(screen.getByText('Editar estructura')).toBeInTheDocument();
      expect(screen.getByText('Eliminar estructura')).toBeInTheDocument();

      const editBtn = screen.getByRole('button', { name: /editar estructura/i });
      fireEvent.click(editBtn);

      expect(screen.getAllByText('Editar estructura').length).toBeGreaterThan(1);
      const cancelBtn = screen.getByRole('button', { name: /cancelar/i });
      fireEvent.click(cancelBtn);
    });
  });
});
