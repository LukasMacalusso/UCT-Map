import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { GlobalModals } from './GlobalModals';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { useAuthState } from '../../states/authState';
import { useUiState } from '../../states/uiState';
import { Role } from '../../constants/role';

const data = vi.hoisted(() => ({
  structures: [] as { id: string; name: string }[],
  users: [] as { id: string; name: string; email: string }[],
  reportsPage: { items: [] as Record<string, unknown>[], totalPages: 1 },
  lostObjects: [] as Record<string, unknown>[],
  meetings: [] as Record<string, unknown>[],
  cancelMeeting: vi.fn(),
}));

vi.mock('../../hooks/useCampus', () => ({
  useStructures: () => ({ data: data.structures }),
}));

vi.mock('../../hooks/useUsers', () => ({
  useUsers: () => ({ data: data.users }),
}));

vi.mock('../../hooks/useReports', () => ({
  useReports: () => ({ data: data.reportsPage }),
}));

vi.mock('../../hooks/useLostObjects', () => ({
  useLostObjectsByIds: () => ({ data: data.lostObjects }),
}));

vi.mock('../../hooks/useSchedule', () => ({
  useAllMeetings: () => ({ data: data.meetings }),
  useUpdateMeetingStatus: () => ({
    mutate: data.cancelMeeting,
    isPending: false,
  }),
}));

const LocationProbe = () => {
  const location = useLocation();
  return <div data-testid="location">{location.pathname}</div>;
};

const renderModals = (path = '/map') =>
  renderWithQueryClient(
    <MemoryRouter initialEntries={[path]}>
      <GlobalModals />
      <LocationProbe />
    </MemoryRouter>,
  );

const setupProfileData = () => {
  useAuthState.getState().mockLoginAs(Role.Admin);
  const user = useAuthState.getState().user!;

  data.structures = [{ id: 's1', name: 'Edificio Uno' }];
  data.users = [{ id: 't1', name: 'Profesor Uno', email: 't1@uct.cl' }];
  data.reportsPage = {
    items: [
      {
        userRefId: user.id,
        lostObjectId: 'lo1',
        structureRefId: 's1',
        complaintDetails: { title: 'Título Uno', description: 'Descripción Uno' },
        ticketType: 0,
        reportedAt: new Date().toISOString(),
      },
      {
        userRefId: user.id,
        lostObjectId: null,
        structureRefId: null,
        complaintDetails: { description: 'Solo descripción' },
        ticketType: 'Unknown',
        reportedAt: new Date().toISOString(),
      },
      {
        userRefId: user.id,
        lostObjectId: null,
        structureRefId: 'missing',
        complaintDetails: { title: 'Solo título' },
        ticketType: 0,
        reportedAt: new Date().toISOString(),
      },
      {
        userRefId: 'other',
        lostObjectId: 'lo3',
        complaintDetails: { title: 'Otro' },
        ticketType: 'Incident',
        reportedAt: new Date().toISOString(),
      },
    ],
    totalPages: 1,
  };
  data.lostObjects = [
    {
      id: 'lo1',
      title: 'Objeto Uno',
      status: 'Lost',
      structureId: 's1',
      reportedAt: new Date().toISOString(),
    },
    {
      id: 'lo2',
      title: 'Objeto Dos',
      status: 'Found',
      structureId: 'missing',
      reportedAt: new Date().toISOString(),
    },
  ];
  data.meetings = [
    {
      id: 'm1',
      studentRefId: user.id,
      teacherRefId: 't1',
      structureRefId: 's1',
      scheduledAt: '2026-01-01T10:00:00',
      durationMinutes: 30,
      status: 'Pending',
    },
    {
      id: 'm2',
      studentRefId: user.id,
      teacherRefId: 'missing',
      structureRefId: null,
      scheduledAt: '2026-01-02T10:00:00',
      durationMinutes: 45,
      status: 'UnknownStatus',
    },
    {
      id: 'm3',
      studentRefId: 'other',
      teacherRefId: 't1',
      structureRefId: 's1',
      scheduledAt: '2026-01-03T10:00:00',
      durationMinutes: 30,
      status: 'Confirmed',
    },
  ];

  return user;
};

describe('GlobalModals', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    data.structures = [];
    data.users = [];
    data.reportsPage = { items: [], totalPages: 1 };
    data.lostObjects = [];
    data.meetings = [];
    useUiState.setState({ activePanel: 'none', editorToast: null });
  });

  it('renders the profile tabs with objects, incidents and meetings data', () => {
    setupProfileData();
    useUiState.setState({ activePanel: 'userProfile' });

    renderModals();

    expect(screen.getByText(/Ingreso:/)).toBeInTheDocument();
    expect(screen.getByText('Objeto Uno')).toBeInTheDocument();
    expect(screen.getByText('Objeto Dos')).toBeInTheDocument();
    expect(screen.getAllByText('Sin ubicación').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole('button', { name: 'Incidencias (3)' }));
    expect(screen.getByText('Título Uno')).toBeInTheDocument();
    expect(screen.getByText(/Descripción Uno/)).toBeInTheDocument();
    expect(screen.getByText('Reporte sin título')).toBeInTheDocument();
    expect(screen.getByText(/Solo descripción/)).toBeInTheDocument();
    expect(screen.getByText(/Sin descripción/)).toBeInTheDocument();
    expect(screen.getAllByText('SIN REVISAR').length).toBeGreaterThan(0);
    expect(screen.getByText('SIN ESTADO')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'Reuniones (2)' }));
    expect(screen.getByText('Prof. Profesor Uno (t1@uct.cl)')).toBeInTheDocument();
    expect(screen.getByText('Prof. Profesor')).toBeInTheDocument();
    expect(screen.getByText('Oficina docente')).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }));
    expect(data.cancelMeeting).toHaveBeenCalledWith({
      id: 'm1',
      status: 'Cancelled',
    });
  });

  it('logs out and navigates to login from the profile', () => {
    setupProfileData();
    useUiState.setState({ activePanel: 'userProfile' });

    renderModals();

    fireEvent.click(screen.getByRole('button', { name: /cerrar sesión/i }));

    expect(useAuthState.getState().user).toBeNull();
    expect(useUiState.getState().activePanel).toBe('none');
    expect(screen.getByTestId('location')).toHaveTextContent('/login');
  });

  it('omits the admission year when the registered date is invalid or missing', () => {
    const user = setupProfileData();
    useUiState.setState({ activePanel: 'userProfile' });

    useAuthState.setState({ user: { ...user, registeredAt: 'not-a-date' } });
    const invalid = renderModals();
    expect(screen.queryByText(/Ingreso:/)).not.toBeInTheDocument();
    invalid.unmount();

    useAuthState.setState({ user: { ...user, registeredAt: undefined } });
    renderModals();
    expect(screen.queryByText(/Ingreso:/)).not.toBeInTheDocument();
  });

  it('does not render the profile when there is no authenticated user', () => {
    useAuthState.setState({ user: null, token: null, isAuthenticated: false });
    useUiState.setState({ activePanel: 'userProfile' });

    renderModals();

    expect(screen.queryByText('TUS CONTRIBUCIONES')).not.toBeInTheDocument();
    expect(screen.queryByText('Información de Cuenta')).not.toBeInTheDocument();
  });

  it.each([
    ['error', 'Error al guardar'],
    ['info', 'Información'],
    ['success', 'Guardado'],
  ])('renders the %s toast', (type, message) => {
    useUiState.setState({
      activePanel: 'none',
      editorToast: { id: 1, message, type: type as 'error' | 'info' | 'success' },
    });

    renderModals();

    expect(screen.getByText(message)).toBeInTheDocument();
  });

  it('hides the toast inside the edition area', () => {
    useUiState.setState({
      activePanel: 'none',
      editorToast: { id: 1, message: 'Toast de edición', type: 'success' },
    });

    renderModals('/edition/map');

    expect(screen.queryByText('Toast de edición')).not.toBeInTheDocument();
  });
});
