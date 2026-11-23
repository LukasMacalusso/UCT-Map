import { screen, fireEvent, act, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { AdministrationView } from './AdministrationView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';

const {
  getAllUsersMock,
  updateUserRoleMock,
  suspendUserMock,
  reactivateUserMock,
} = vi.hoisted(() => ({
  getAllUsersMock: vi.fn(),
  updateUserRoleMock: vi.fn(),
  suspendUserMock: vi.fn(),
  reactivateUserMock: vi.fn(),
}));

vi.mock('../services/userService', () => ({
  userService: {
    getAllUsers: getAllUsersMock,
    suspendUser: suspendUserMock,
    reactivateUser: reactivateUserMock,
    updateUserRole: updateUserRoleMock,
  },
}));

const makeUsers = (total: number): UserIdentity[] =>
  Array.from({ length: total }, (_, i) => ({
    id: i === 0 ? '123' : `u${i}`,
    name: `Usuario ${i}`,
    email: `user${i}@uct.cl`,
    role: Role.Student,
    isSuspended: false,
  }));

describe('AdministrationView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Admin);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('lista los usuarios cargados', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    expect(await screen.findByText('Usuario 0')).toBeInTheDocument();
    expect(screen.getByText('Usuario 2')).toBeInTheDocument();
  });

  it('muestra la paginación según la cantidad de contenido', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(25));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    expect(screen.getByLabelText('Ir a la página 2')).toBeInTheDocument();
  });

  it('navega a la segunda página', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(25));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getByLabelText('Ir a la página 2'));

    expect(await screen.findByText('Usuario 20')).toBeInTheDocument();
    expect(screen.queryByText('Usuario 0')).not.toBeInTheDocument();
  });

  it('oculta la paginación cuando hay una sola página', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(5));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    expect(screen.queryByLabelText('Paginación')).not.toBeInTheDocument();
  });

  it('no permite suspender la propia cuenta del administrador', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    const selfButton = screen.getByTitle('No puedes suspender tu propia cuenta');
    expect(selfButton).toBeDisabled();
  });

  it('abre el perfil del usuario al hacer click en "Ver perfil"', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: /ver perfil/i })[0]);

    expect(await screen.findByText('Información de Cuenta')).toBeInTheDocument();
  });

  it('dice "Tus Contribuciones" al abrir tu propio perfil', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: /ver perfil/i })[0]);

    expect(await screen.findByText('Tus Contribuciones')).toBeInTheDocument();
  });

  it('dice "Contribuciones" (sin "Tus") al abrir el perfil de otro usuario', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: /ver perfil/i })[1]);

    expect(await screen.findByText('Contribuciones')).toBeInTheDocument();
    expect(screen.queryByText('Tus Contribuciones')).not.toBeInTheDocument();
  });

  it('filtra para ver solo los suspendidos', async () => {
    const users = makeUsers(3);
    users[1] = { ...users[1], isSuspended: true };
    getAllUsersMock.mockResolvedValue(users);
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: 'Todos los roles' })[0]);
    fireEvent.click(screen.getByRole('button', { name: 'Suspendidos' }));

    expect(screen.getByText('Usuario 1')).toBeInTheDocument();
    expect(screen.queryByText('Usuario 0')).not.toBeInTheDocument();
    expect(screen.queryByText('Usuario 2')).not.toBeInTheDocument();
  });

  it('permite buscar usuarios por nombre y recargar la lista', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(5));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');

    const searchInput = screen.getByPlaceholderText('Buscar por nombre o correo...');
    fireEvent.change(searchInput, { target: { value: 'Usuario 3' } });

    expect(screen.getByText('Usuario 3')).toBeInTheDocument();
    expect(screen.queryByText('Usuario 0')).not.toBeInTheDocument();

    const refreshBtn = screen.getByRole('button', { name: /actualizar/i });
    fireEvent.click(refreshBtn);
    expect(getAllUsersMock).toHaveBeenCalled();
  });

  it('muestra el spinner mientras carga y el error de carga', async () => {
    getAllUsersMock.mockReturnValue(new Promise(() => {}));
    const loading = renderWithQueryClient(<AdministrationView />);
    expect(screen.getByText('Cargando usuarios...')).toBeInTheDocument();
    loading.unmount();

    getAllUsersMock.mockRejectedValue(new Error('fail'));
    renderWithQueryClient(<AdministrationView />);
    expect(
      await screen.findByText(
        'No se pudieron cargar los usuarios. Intenta nuevamente.',
      ),
    ).toBeInTheDocument();
  });

  it('filtra por rol y muestra el estado vacío', async () => {
    const users = makeUsers(3);
    users[1] = { ...users[1], role: Role.Teacher };
    getAllUsersMock.mockResolvedValue(users);
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: 'Todos los roles' })[0]);
    fireEvent.click(screen.getAllByRole('button', { name: 'Profesor' })[0]);

    expect(screen.getByText('Usuario 1')).toBeInTheDocument();
    expect(screen.queryByText('Usuario 0')).not.toBeInTheDocument();

    fireEvent.click(screen.getAllByRole('button', { name: 'Profesor' })[0]);
    fireEvent.click(screen.getAllByRole('button', { name: 'Administrador' })[0]);

    expect(screen.getByText('No se encontraron usuarios')).toBeInTheDocument();
  });

  it('no abre la confirmación si el rol elegido es el mismo', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(2));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 1');
    const studentButtons = screen.getAllByRole('button', { name: 'Estudiante' });
    fireEvent.click(studentButtons[1]);
    fireEvent.click(studentButtons[2]);

    expect(screen.queryByText('Cambiar rol')).not.toBeInTheDocument();
  });

  it('muestra error si falla el cambio de rol', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(2));
    updateUserRoleMock.mockRejectedValue(new Error('fail'));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 1');

    vi.useFakeTimers();
    const studentButtons = screen.getAllByRole('button', { name: 'Estudiante' });
    fireEvent.click(studentButtons[1]);
    const teacherButtons = screen.getAllByRole('button', { name: 'Profesor' });
    fireEvent.click(teacherButtons[1]);
    expect(screen.getByText('Cambiar rol')).toBeInTheDocument();
    act(() => {
      vi.advanceTimersByTime(2100);
    });
    fireEvent.click(screen.getByText('Sí, cambiar rol'));
    vi.useRealTimers();

    expect(
      await screen.findByText('No se pudo cambiar el rol del usuario.'),
    ).toBeInTheDocument();
  });

  it('muestra error si falla la suspensión', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(2));
    suspendUserMock.mockRejectedValue(new Error('fail'));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 1');

    vi.useFakeTimers();
    fireEvent.click(screen.getAllByRole('button', { name: 'SUSPENDER' })[1]);
    expect(screen.getByText('Suspender cuenta')).toBeInTheDocument();
    act(() => {
      vi.advanceTimersByTime(3100);
    });
    fireEvent.click(screen.getByText('Sí, suspender'));
    vi.useRealTimers();

    expect(
      await screen.findByText('No se pudo cambiar el estado de la cuenta.'),
    ).toBeInTheDocument();
  });

  it('muestra el estado de actualización al recargar', async () => {
    let calls = 0;
    getAllUsersMock.mockImplementation(() => {
      calls += 1;
      return calls === 1 ? Promise.resolve(makeUsers(2)) : new Promise(() => {});
    });
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getByRole('button', { name: /actualizar/i }));

    await waitFor(() =>
      expect(screen.getByRole('button', { name: /actualizar/i })).toBeDisabled(),
    );
  });
});
