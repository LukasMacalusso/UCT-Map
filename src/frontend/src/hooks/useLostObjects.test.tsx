import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  useLostObjects,
  useLostObjectsByIds,
  useCreateLostObject,
  useUpdateLostObjectStatus,
  useDeleteLostObject,
} from './useLostObjects';
import { incidentService } from '../services/incidentService';
import { LostObjectStatus } from '../constants/lostObjectsStatus';
import type { LostObjectPageDto } from '../dtos/incident/objects/LostObjectPageDto';
import type { LostObjectDto } from '../dtos/incident/objects/LostObjectDto';

vi.mock('../services/incidentService');

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useLostObjects hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('queries useLostObjects and useLostObjectsByIds', async () => {
    vi.mocked(incidentService.searchLostObjects).mockResolvedValue({ items: [], totalPages: 1 } as unknown as LostObjectPageDto);
    vi.mocked(incidentService.getLostObject).mockResolvedValue({ id: 'lo1', title: 'Lost 1' } as unknown as LostObjectDto);

    const wrapper = createWrapper();
    const { result: loHook } = renderHook(() => useLostObjects({ page: 1 }), { wrapper });
    await waitFor(() => expect(loHook.current.isSuccess).toBe(true));

    const { result: idsHook } = renderHook(() => useLostObjectsByIds(['lo1']), { wrapper });
    await waitFor(() => expect(idsHook.current.isSuccess).toBe(true));
    expect(idsHook.current.data?.length).toBe(1);
  });

  it('lost object mutations: create, update, delete', async () => {
    vi.mocked(incidentService.createLostObject).mockResolvedValue('lo-new');
    vi.mocked(incidentService.updateLostObjectStatus).mockResolvedValue();
    vi.mocked(incidentService.deleteLostObject).mockResolvedValue();

    const wrapper = createWrapper();
    const { result: createHook } = renderHook(() => useCreateLostObject(), { wrapper });
    await act(async () => {
      await createHook.current.mutateAsync({ title: 'Keys', description: 'Car keys', structureId: 'st1' });
    });
    expect(incidentService.createLostObject).toHaveBeenCalled();

    const { result: updateHook } = renderHook(() => useUpdateLostObjectStatus(), { wrapper });
    await act(async () => {
      await updateHook.current.mutateAsync({ id: 'lo1', status: LostObjectStatus.Resolved });
    });
    expect(incidentService.updateLostObjectStatus).toHaveBeenCalledWith('lo1', LostObjectStatus.Resolved);

    const { result: deleteHook } = renderHook(() => useDeleteLostObject(), { wrapper });
    await act(async () => {
      await deleteHook.current.mutateAsync('lo1');
    });
    expect(incidentService.deleteLostObject).toHaveBeenCalledWith('lo1');
  });
});
