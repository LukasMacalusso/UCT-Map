import { screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdministrationView } from './AdministrationView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';

const { getAllUsersMock } = vi.hoisted(() => ({ getAllUsersMock: vi.fn() }));

vi.mock('../services/userService', () => ({
  userService: {
    getAllUsers: getAllUsersMock,
    suspendUser: vi.fn(),
    reactivateUser: vi.fn(),
    updateUserRole: vi.fn(),
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
    fireEvent.click(screen.getAllByRole('button', { name: 'Ver perfil' })[0]);

    expect(await screen.findByText('Información de Cuenta')).toBeInTheDocument();
  });

  it('dice "Tus Contribuciones" al abrir tu propio perfil', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: 'Ver perfil' })[0]);

    expect(await screen.findByText('Tus Contribuciones')).toBeInTheDocument();
  });

  it('dice "Contribuciones" (sin "Tus") al abrir el perfil de otro usuario', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    renderWithQueryClient(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getAllByRole('button', { name: 'Ver perfil' })[1]);

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
});
