import { describe, it, expect, vi, beforeEach } from 'vitest';
import { authService } from './authService';
import httpClient from '../api/httpClient';

vi.mock('../api/httpClient');

describe('authService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('login sends credentials and returns response', async () => {
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { token: 'jwt-123' } });
    const res = await authService.login('test@uct.cl', 'pass');
    expect(res).toEqual({ token: 'jwt-123' });
    expect(httpClient.post).toHaveBeenCalledWith('/api/identity/login', {
      email: 'test@uct.cl',
      password: 'pass',
    });
  });

  it('register sends payload and returns response', async () => {
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'u1' } });
    const res = await authService.register('Nacho', 'nacho@uct.cl', 'pass123');
    expect(res).toEqual({ id: 'u1' });
    expect(httpClient.post).toHaveBeenCalledWith('/api/identity/register', {
      name: 'Nacho',
      email: 'nacho@uct.cl',
      password: 'pass123',
    });
  });

  it('throws ApiError with friendly message on failure', async () => {
    vi.mocked(httpClient.post).mockRejectedValueOnce({
      isAxiosError: true,
      response: { status: 401 },
    });
    await expect(authService.login('a@b.cl', 'wrong')).rejects.toThrow('Credenciales inválidas');
  });
});
