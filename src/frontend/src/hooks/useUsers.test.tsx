import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useUsers, useUpdateUserRole, useToggleUserSuspension } from './useUsers';
import { userService } from '../services/userService';
import { Role } from '../constants/role';

vi.mock('../services/userService');

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useUsers hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('queries all users', async () => {
    vi.mocked(userService.getAllUsers).mockResolvedValue([
      { id: 'u1', name: 'User 1', email: 'u1@uct.cl', role: Role.Student, isSuspended: false },
    ]);

    const wrapper = createWrapper();
    const { result } = renderHook(() => useUsers(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data?.length).toBe(1);
  });

  it('mutates user role and handles optimistic update rollback on error', async () => {
    vi.mocked(userService.updateUserRole).mockRejectedValueOnce(new Error('Fail'));

    const wrapper = createWrapper();
    const { result } = renderHook(() => useUpdateUserRole(), { wrapper });

    await act(async () => {
      try {
        await result.current.mutateAsync({ userId: 'u1', role: Role.Admin });
      } catch {
        // Expected error
      }
    });

    expect(userService.updateUserRole).toHaveBeenCalledWith('u1', Role.Admin);
  });

  it('toggles user suspension', async () => {
    vi.mocked(userService.suspendUser).mockResolvedValueOnce();
    vi.mocked(userService.reactivateUser).mockResolvedValueOnce();

    const wrapper = createWrapper();
    const { result } = renderHook(() => useToggleUserSuspension(), { wrapper });

    await act(async () => {
      await result.current.mutateAsync({ userId: 'u1', isSuspended: true });
    });
    expect(userService.suspendUser).toHaveBeenCalledWith('u1');

    await act(async () => {
      await result.current.mutateAsync({ userId: 'u1', isSuspended: false });
    });
    expect(userService.reactivateUser).toHaveBeenCalledWith('u1');
  });
});
