import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AdministrationView } from './AdministrationView';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';

const { getAllUsersMock } = vi.hoisted(() => ({ getAllUsersMock: vi.fn() }));

vi.mock('../services/userManagementService', () => ({
  userManagementService: {
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
    render(<AdministrationView />);

    expect(await screen.findByText('Usuario 0')).toBeInTheDocument();
    expect(screen.getByText('Usuario 2')).toBeInTheDocument();
  });

  it('muestra la paginación según la cantidad de contenido', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(25));
    render(<AdministrationView />);

    await screen.findByText('Usuario 0');
    expect(screen.getByLabelText('Ir a la página 2')).toBeInTheDocument();
  });

  it('navega a la segunda página', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(25));
    render(<AdministrationView />);

    await screen.findByText('Usuario 0');
    fireEvent.click(screen.getByLabelText('Ir a la página 2'));

    expect(await screen.findByText('Usuario 20')).toBeInTheDocument();
    expect(screen.queryByText('Usuario 0')).not.toBeInTheDocument();
  });

  it('oculta la paginación cuando hay una sola página', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(5));
    render(<AdministrationView />);

    await screen.findByText('Usuario 0');
    expect(screen.queryByLabelText('Paginación')).not.toBeInTheDocument();
  });

  it('no permite suspender la propia cuenta del administrador', async () => {
    getAllUsersMock.mockResolvedValue(makeUsers(3));
    render(<AdministrationView />);

    await screen.findByText('Usuario 0');
    const selfButton = screen.getByTitle('No puedes suspender tu propia cuenta');
    expect(selfButton).toBeDisabled();
  });
});
