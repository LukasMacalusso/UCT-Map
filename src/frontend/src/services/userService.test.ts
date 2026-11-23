import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../api/httpClient', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}));

import httpClient from '../api/httpClient';
import { userService } from './userService';
import { Role } from '../constants/role';

const mocked = httpClient as unknown as {
  get: ReturnType<typeof vi.fn>;
  post: ReturnType<typeof vi.fn>;
  put: ReturnType<typeof vi.fn>;
  delete: ReturnType<typeof vi.fn>;
};

describe('userService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getAllUsers mapea el DTO y valida el rol', async () => {
    mocked.get.mockResolvedValue({
      data: [
        { userId: '1', name: 'Ana', email: 'ana@uct.cl', role: 'Teacher', isSuspended: true },
        { userId: '2', name: 'Beto', email: 'beto@uct.cl', role: 'RolDesconocido', isSuspended: false },
      ],
    });

    const users = await userService.getAllUsers();

    expect(mocked.get).toHaveBeenCalledWith('/api/identity');
    expect(users[0]).toEqual({
      id: '1',
      name: 'Ana',
      email: 'ana@uct.cl',
      role: Role.Teacher,
      isSuspended: true,
    });
    expect(users[1].role).toBe(Role.Student);
  });

  it('suspendUser hace POST al endpoint de suspensión', async () => {
    mocked.post.mockResolvedValue({});
    await userService.suspendUser('abc');
    expect(mocked.post).toHaveBeenCalledWith('/api/identity/abc/suspension', {});
  });

  it('reactivateUser hace DELETE al endpoint de suspensión', async () => {
    mocked.delete.mockResolvedValue({});
    await userService.reactivateUser('abc');
    expect(mocked.delete).toHaveBeenCalledWith('/api/identity/abc/suspension', {});
  });

  it('updateUserRole hace PUT reemplazando los roles por el nuevo', async () => {
    mocked.put.mockResolvedValue({});
    await userService.updateUserRole('abc', Role.Admin);
    expect(mocked.put).toHaveBeenCalledWith('/api/identity/abc/roles', { roles: [Role.Admin] });
  });
});
