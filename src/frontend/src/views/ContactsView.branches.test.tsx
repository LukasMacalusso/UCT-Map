import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ContactsView } from './ContactsView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

const state = vi.hoisted(() => ({
  users: [] as Record<string, unknown>[],
  usersLoading: false,
  usersError: null as { message?: string } | null,
  officeHours: [] as Record<string, unknown>[],
  officeHoursLoading: false,
  campuses: [] as Record<string, unknown>[],
  structures: [] as Record<string, unknown>[],
  availability: undefined as Record<string, unknown> | undefined,
  availabilityLoading: false,
  meetings: [] as Record<string, unknown>[],
  meetingsLoading: false,
  createMeeting: {
    mutate: vi.fn(
      (_payload: unknown, options?: { onSuccess?: () => void }) => options?.onSuccess?.(),
    ),
    isPending: false,
    error: null as { message: string } | null,
    reset: vi.fn(),
  },
}));

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: state.users,
    isLoading: state.usersLoading,
    isError: Boolean(state.usersError),
    error: state.usersError,
  }),
}));

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({ data: state.campuses }),
  useStructures: () => ({ data: state.structures }),
}));

vi.mock('../hooks/useSchedule', () => ({
  useOfficeHours: () => ({
    data: state.officeHours,
    isLoading: state.officeHoursLoading,
  }),
  useTeacherAvailability: () => ({
    data: state.availability,
    isLoading: state.availabilityLoading,
  }),
  useTeacherMeetings: () => ({
    data: state.meetings,
    isLoading: state.meetingsLoading,
  }),
  useCreateMeeting: () => state.createMeeting,
}));

const teacher = (id: string, name: string, email: string) => ({
  id,
  name,
  email,
  role: Role.Teacher,
  isSuspended: false,
});

const officeHour = (
  id: string,
  teacherRefId: string,
  dayOfWeek: string,
  startTime: string,
  endTime: string,
  structureRefId: string | null,
) => ({ id, teacherRefId, dayOfWeek, startTime, endTime, structureRefId });

const renderView = () =>
  renderWithQueryClient(
    <MemoryRouter>
      <ContactsView />
    </MemoryRouter>,
  );

const selectOption = (currentLabel: string, optionLabel: string) => {
  fireEvent.click(screen.getAllByRole('button', { name: currentLabel })[0]);
  fireEvent.click(screen.getByRole('button', { name: optionLabel }));
};

describe('ContactsView branches', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    state.users = [];
    state.usersLoading = false;
    state.usersError = null;
    state.officeHours = [];
    state.officeHoursLoading = false;
    state.campuses = [];
    state.structures = [];
    state.availability = undefined;
    state.availabilityLoading = false;
    state.meetings = [];
    state.meetingsLoading = false;
    state.createMeeting.isPending = false;
    state.createMeeting.error = null;
    useAuthState.getState().mockLoginAs(Role.Student);
  });

  it('shows the loading state for users and for office hours', () => {
    state.usersLoading = true;
    const usersLoading = renderView();
    expect(
      screen.getByText('Cargando directorio de profesores...'),
    ).toBeInTheDocument();
    usersLoading.unmount();

    state.usersLoading = false;
    state.officeHoursLoading = true;
    renderView();
    expect(
      screen.getByText('Cargando directorio de profesores...'),
    ).toBeInTheDocument();
  });

  it('shows the API error message or its default fallback', () => {
    state.usersError = { message: 'Error de prueba' };
    const withMessage = renderView();
    expect(screen.getByText('Error de prueba')).toBeInTheDocument();
    withMessage.unmount();

    state.usersError = {};
    renderView();
    expect(
      screen.getByText('No se pudieron cargar los profesores.'),
    ).toBeInTheDocument();
  });

  it('shows the empty state when there are no visible teachers', () => {
    state.users = [
      {
        id: 'u1',
        name: 'Alumno',
        email: 'alumno@uct.cl',
        role: Role.Student,
        isSuspended: false,
      },
      {
        id: 'u2',
        name: 'Suspendido',
        email: 'suspendido@uct.cl',
        role: Role.Teacher,
        isSuspended: true,
      },
    ];

    renderView();

    expect(
      screen.getByText(
        'No hay profesores que coincidan con los filtros seleccionados.',
      ),
    ).toBeInTheDocument();
  });

  it('resolves campus, office and schedule summaries for each teacher', () => {
    state.users = [
      teacher('u1', 'Ana', 'ana@uct.cl'),
      teacher('u2', 'Beto', 'beto@uct.cl'),
      teacher('u3', 'Carla', 'carla@uct.cl'),
      teacher('u4', 'Diego', 'diego@uct.cl'),
    ];
    state.campuses = [
      { id: 'c1', name: 'Campus Uno' },
      { id: 'c2', name: 'Campus Dos' },
    ];
    state.structures = [
      { id: 's1', name: 'Edificio Uno', campusId: 'c1' },
      { id: 's2', name: 'Edificio Dos', campusId: 'c2' },
      { id: 's3', name: 'Edificio Tres', campusId: 'c3' },
      { id: 's4', name: 'Edificio Cuatro', campusId: undefined },
    ];
    state.officeHours = [
      officeHour('oh1', 'u1', 'Monday', '09:00:00', '11:00:00', 's1'),
      officeHour('oh2', 'u1', 'Tuesday', '10:00:00', '12:00:00', 's2'),
      officeHour('oh3', 'u3', 'Wednesday', '08:00:00', '10:00:00', 's3'),
      officeHour('oh4', 'u3', 'Thursday', '08:00:00', '10:00:00', null),
      officeHour('oh5', 'u3', 'Friday', '08:00:00', '10:00:00', 'missing'),
      officeHour('oh6', 'u4', 'Saturday', '09:00:00', '10:00:00', 's4'),
    ];

    renderView();

    expect(screen.getAllByText('Campus Uno').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Edificio Uno').length).toBeGreaterThan(0);
    expect(screen.getByText(/\(\+1 más\)/)).toBeInTheDocument();
    expect(screen.getAllByText('Edificio Tres').length).toBeGreaterThan(0);
    expect(screen.getByText(/\(\+2 más\)/)).toBeInTheDocument();
    expect(screen.getAllByText('Edificio Cuatro').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Ubicación por confirmar').length).toBeGreaterThan(0);
    expect(screen.getByText('Sin horario de atención registrado')).toBeInTheDocument();
  });

  it('filters by text, availability, day, structure and campus', () => {
    state.users = [
      teacher('u1', 'Ana', 'ana@uct.cl'),
      teacher('u2', 'Beto', 'beto@uct.cl'),
      teacher('u3', 'Carla', 'carla@uct.cl'),
    ];
    state.campuses = [
      { id: 'c1', name: 'Campus Uno' },
      { id: 'c2', name: 'Campus Dos' },
    ];
    state.structures = [
      { id: 's1', name: 'Edificio Uno', campusId: 'c1' },
      { id: 's2', name: 'Edificio Dos', campusId: 'c2' },
    ];
    state.officeHours = [
      officeHour('oh1', 'u1', 'Monday', '09:00:00', '11:00:00', 's1'),
      officeHour('oh2', 'u1', 'Tuesday', '10:00:00', '12:00:00', 's2'),
      officeHour('oh3', 'u3', 'Wednesday', '08:00:00', '10:00:00', null),
    ];

    renderView();

    const search = screen.getByPlaceholderText(
      'Buscar profesor por nombre o correo...',
    );
    fireEvent.change(search, { target: { value: 'beto' } });
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);

    fireEvent.change(search, { target: { value: 'ana@' } });
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);
    fireEvent.change(search, { target: { value: '' } });
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(3);

    selectOption('Todos los profesores', 'Con horario de atención');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(2);

    selectOption('Con horario de atención', 'Sin horario registrado');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);

    selectOption('Sin horario registrado', 'Todos los profesores');
    selectOption('Todos los días', 'Lunes');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);
    selectOption('Lunes', 'Todos los días');

    selectOption('Todos los edificios', 'Edificio Uno');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);
    selectOption('Edificio Uno', 'Todos los edificios');

    selectOption('Todos los campus', 'Campus Dos');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);

    selectOption('Todos los edificios', 'Edificio Dos');
    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(1);
  }, 20000);

  it('paginates the teacher directory', () => {
    state.users = Array.from({ length: 12 }, (_, index) =>
      teacher(`u${index + 1}`, `Profesor ${index + 1}`, `p${index + 1}@uct.cl`),
    );

    renderView();

    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(10);
    expect(screen.getAllByText('Profesor 1').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByLabelText('Ir a la página 2'));

    expect(screen.getAllByRole('button', { name: /info/i })).toHaveLength(2);
    expect(screen.getAllByText('Profesor 11').length).toBeGreaterThan(0);
    expect(screen.getAllByText('Profesor 12').length).toBeGreaterThan(0);
  });

  it('opens the profile and books an available slot', () => {
    state.users = [teacher('u1', 'Ana', 'ana@uct.cl')];
    state.campuses = [{ id: 'c1', name: 'Campus Uno' }];
    state.structures = [{ id: 's1', name: 'Edificio Uno', campusId: 'c1' }];
    state.officeHours = [
      officeHour('oh1', 'u1', 'Monday', '09:00:00', '11:00:00', 's1'),
    ];

    renderView();

    fireEvent.click(screen.getByRole('button', { name: /info/i }));
    expect(state.createMeeting.reset).toHaveBeenCalled();
    expect(screen.getByText('Atención Estudiantes')).toBeInTheDocument();

    const dayButton = screen
      .getAllByText(/bloques? libres?/)[0]
      .closest('button');
    fireEvent.click(dayButton!);

    fireEvent.click(screen.getByRole('button', { name: /09:00/ }));
    fireEvent.click(screen.getByRole('button', { name: /reservar hora/i }));

    expect(state.createMeeting.mutate).toHaveBeenCalledWith(
      expect.objectContaining({
        teacherRefId: 'u1',
        studentRefId: '123',
        structureRefId: 's1',
        durationMinutes: 30,
      }),
      expect.any(Object),
    );
    expect(screen.getByText(/Reunión agendada para/)).toBeInTheDocument();
  });

  it('uses availability blocks, shows loading and booking states, and closes the profile', () => {
    state.users = [teacher('u1', 'Ana', 'ana@uct.cl')];
    state.availability = {
      availableBlocks: [
        officeHour('oh9', 'u1', 'Friday', '15:00:00', '16:00:00', 's1'),
      ],
    };
    state.availabilityLoading = true;
    state.meetingsLoading = true;
    state.createMeeting.isPending = true;
    state.createMeeting.error = { message: 'Error de reserva' };

    renderView();

    fireEvent.click(screen.getByRole('button', { name: /info/i }));

    expect(screen.getByText('Cargando horarios...')).toBeInTheDocument();
    expect(screen.getByText('Calculando disponibilidad...')).toBeInTheDocument();
    expect(screen.getByText('Error de reserva')).toBeInTheDocument();
    expect(screen.getByText('RESERVANDO...')).toBeInTheDocument();

    state.availabilityLoading = false;
    state.meetingsLoading = false;
    state.createMeeting.isPending = false;
    state.createMeeting.error = null;

    fireEvent.click(screen.getByRole('button', { name: 'Cerrar' }));
    expect(screen.queryByText('Atención Estudiantes')).not.toBeInTheDocument();
  });

  it('shows the availability blocks when no schedule is loading', () => {
    state.users = [teacher('u1', 'Ana', 'ana@uct.cl')];
    state.availability = {
      availableBlocks: [
        officeHour('oh9', 'u1', 'Friday', '15:00:00', '16:00:00', 's1'),
      ],
    };
    state.structures = [{ id: 's1', name: 'Edificio Uno', campusId: 'c1' }];

    renderView();

    fireEvent.click(screen.getByRole('button', { name: /info/i }));

    expect(screen.getByText('1 BLOQUE')).toBeInTheDocument();
    expect(screen.getByText('Viernes · 15:00 - 16:00')).toBeInTheDocument();
    expect(screen.getAllByText('Edificio Uno').length).toBeGreaterThan(0);
  });
});
