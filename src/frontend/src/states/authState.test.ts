import { describe, it, expect, beforeEach } from 'vitest';
import { useAuthState } from './authState';

describe('useAuthState store', () => {
  beforeEach(() => {
    localStorage.clear();
    useAuthState.getState().logout();
  });

  it('initializes in unauthenticated state by default', () => {
    const state = useAuthState.getState();
    expect(state.isAuthenticated).toBe(false);
    expect(state.user).toBeNull();
    expect(state.token).toBeNull();
  });

  it('saves session and persists to localStorage on login', () => {
    const mockUser = {
      id: '1',
      name: 'Nacho',
      email: 'nacho@uct.cl',
      role: 'ADMIN' as const,
      registeredAt: '2026-10-11',
    };

    useAuthState.getState().login('jwt_12345', mockUser);

    const state = useAuthState.getState();
    expect(state.isAuthenticated).toBe(true);
    expect(state.user?.role).toBe('ADMIN');
    expect(localStorage.getItem('jwt_token')).toBe('jwt_12345');
    expect(JSON.parse(localStorage.getItem('user_identity') || '{}').name).toBe('Nacho');
  });

  it('removes data from localStorage on logout', () => {
    useAuthState.getState().mockLoginAs('TEACHER');
    expect(useAuthState.getState().isAuthenticated).toBe(true);

    useAuthState.getState().logout();

    expect(useAuthState.getState().isAuthenticated).toBe(false);
    expect(useAuthState.getState().user).toBeNull();
    expect(localStorage.getItem('jwt_token')).toBeNull();
    expect(localStorage.getItem('user_identity')).toBeNull();
  });
});
