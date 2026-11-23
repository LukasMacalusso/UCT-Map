import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ScheduleView as TeacherView } from './TeacherView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

const state = vi.hoisted(() => ({
  workload: undefined as Record<string, unknown> | undefined,
  isLoading: false,
  isFetching: false,
  isError: false,
  error: null as { message?: string } | null,
  refetch: vi.fn(),
  createOfficeHour: {
    mutate: vi.fn(),
    reset: vi.fn(),
    isPending: false,
    error: null as { message?: string } | null,
  },
}));

vi.mock('../hooks/useSchedule', () => ({
  useTeacherWorkload: () => ({
    data: state.workload,
    isLoading: state.isLoading,
    isFetching: state.isFetching,
    isError: state.isError,
    error: state.error,
    refetch: state.refetch,
  }),
  useUpdateMeetingStatus: () => ({
    mutate: vi.fn(),
    isPending: false,
  }),
  useCreateOfficeHour: () => state.createOfficeHour,
}));

vi.mock('../hooks/useCampus', () => ({
  useStructures: () => ({
    data: [{ id: 'st1', name: 'Oficina 301' }],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: [{ id: 's1', name: 'Estudiante Juan', email: 'juan@uct.cl' }],
    isLoading: false,
  }),
}));

const officeHour = (
  id: string,
  dayOfWeek: string,
  startTime: string,
  endTime: string,
  structureRefId: string | null,
) => ({ id, dayOfWeek, startTime, endTime, structureRefId });

const meeting = (
  id: string,
  studentRefId: string,
  scheduledAt: string,
  durationMinutes: number,
  status: string,
  structureRefId: string | null,
) => ({
  id,
  teacherRefId: 't1',
  studentRefId,
  scheduledAt,
  durationMinutes,
  status,
  structureRefId,
});

const renderView = () =>
  renderWithQueryClient(
    <MemoryRouter>
      <TeacherView />
    </MemoryRouter>,
  );

const fullWorkload = () => ({
  teacherId: 't1',
  weeklyOfficeHourMinutes: 90,
  officeHours: [
    officeHour('oh1', 'Monday', '09:00:00', '11:00:00', 'st1'),
    officeHour('oh2', 'Tuesday', '10:00:00', '11:00:00', null),
  ],
  meetings: [
    meeting('m1', 's1', '2026-11-03T10:00:00Z', 30, 'Confirmed', 'st1'),
    meeting('m2', 'missing', '2026-11-04T10:00:00Z', 45, 'Cancelled', null),
  ],
});

describe('TeacherView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    state.workload = undefined;
    state.isLoading = false;
    state.isFetching = false;
    state.isError = false;
    state.error = null;
    state.createOfficeHour.isPending = false;
    state.createOfficeHour.error = null;
    useAuthState.getState().mockLoginAs(Role.Teacher);
  });

  it('renders teacher workload, schedule and meetings', () => {
    state.workload = fullWorkload();

    renderView();

    expect(screen.getByText('Mis Bloques de Atención')).toBeInTheDocument();
    expect(screen.getByText('Reuniones Agendadas')).toBeInTheDocument();
    expect(screen.getByText('1 h 30 min')).toBeInTheDocument();
    expect(screen.getByText('2 bloques activos')).toBeInTheDocument();
    expect(screen.getByText('30 min')).toBeInTheDocument();
    expect(screen.getByText('Estudiante Juan (juan@uct.cl)')).toBeInTheDocument();
    expect(screen.getByText('Estudiante (missing)')).toBeInTheDocument();
    expect(screen.getAllByText('Oficina 301').length).toBeGreaterThan(0);
    expect(screen.getByText('Ubicación por confirmar')).toBeInTheDocument();
    expect(screen.getByText('Oficina docente')).toBeInTheDocument();
  });

  it('opens the create office hour modal for the current teacher', () => {
    state.workload = fullWorkload();

    renderView();

    fireEvent.click(screen.getByRole('button', { name: /agregar/i }));

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(screen.getByText('Nuevo Bloque de Atención')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /guardar bloque/i }));

    expect(state.createOfficeHour.mutate).toHaveBeenCalledWith(
      expect.objectContaining({ teacherRefId: '123' }),
      expect.anything(),
    );
  });

  it.each([
    [30, '30 min'],
    [60, '1 hrs'],
    [90, '1 h 30 min'],
    [0, '0 min'],
  ])('formats %s weekly minutes as %s', (minutes, label) => {
    state.workload = {
      teacherId: 't1',
      weeklyOfficeHourMinutes: minutes,
      officeHours: [],
      meetings: [],
    };

    renderView();

    expect(screen.getAllByText(label).length).toBeGreaterThan(0);
  });

  it('renders empty states when there are no blocks or meetings', () => {
    state.workload = {
      teacherId: 't1',
      weeklyOfficeHourMinutes: 0,
      officeHours: [],
      meetings: [],
    };

    renderView();

    expect(
      screen.getByText('No tienes bloques de atención semanal registrados.'),
    ).toBeInTheDocument();
    expect(
      screen.getByText(
        'No hay reuniones agendadas que coincidan con el filtro seleccionado.',
      ),
    ).toBeInTheDocument();
  });

  it('handles undefined workload data', () => {
    renderView();

    expect(screen.getAllByText('0 min').length).toBeGreaterThan(0);
  });

  it('filters meetings by status', () => {
    state.workload = fullWorkload();

    renderView();

    fireEvent.click(screen.getAllByRole('button', { name: 'Todos los estados' })[0]);
    fireEvent.click(screen.getAllByRole('button', { name: 'Cancelada' })[0]);

    expect(screen.getByText('Estudiante (missing)')).toBeInTheDocument();
    expect(screen.queryByText('Estudiante Juan (juan@uct.cl)')).not.toBeInTheDocument();
  });

  it('changes the date range and refreshes', () => {
    state.workload = fullWorkload();

    renderView();

    fireEvent.click(screen.getAllByRole('button', { name: 'Próximos 14 días' })[0]);
    fireEvent.click(screen.getByRole('button', { name: 'Próximos 7 días' }));
    expect(screen.getAllByText('Próximos 7 días').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole('button', { name: /actualizar/i }));
    expect(state.refetch).toHaveBeenCalled();
  });

  it('shows loading, refreshing and error states', () => {
    state.isLoading = true;
    const loading = renderView();
    expect(
      screen.getByText('Cargando carga académica y reuniones...'),
    ).toBeInTheDocument();
    loading.unmount();

    state.isLoading = false;
    state.isFetching = true;
    const refreshing = renderView();
    expect(screen.getByRole('button', { name: /actualizar/i })).toBeDisabled();
    refreshing.unmount();

    state.isFetching = false;
    state.isError = true;
    state.error = { message: 'Fallo de prueba' };
    const withMessage = renderView();
    expect(screen.getByText('Fallo de prueba')).toBeInTheDocument();
    withMessage.unmount();

    state.error = {};
    renderView();
    expect(
      screen.getByText('No se pudo cargar la información de tu horario.'),
    ).toBeInTheDocument();
  });
});
