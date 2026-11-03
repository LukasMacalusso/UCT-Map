import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  useCampuses,
  useCreateCampus,
  useUpdateCampus,
  useDeleteCampus,
  useBuildingLocations,
  useSearchRooms,
  useStructures,
  useBuildingRooms,
  useCreateRoom,
  useUpdateRoom,
  useDeleteRoom,
  useCreateBuilding,
  useUpdateBuilding,
  useDeleteBuilding,
  useCreateStructure,
  useUpdateStructure,
  useDeleteStructure,
  useCategories,
  useCreateCategory,
  useUpdateCategory,
  useReorderCategories,
  useDeleteCategory,
} from './useCampus';
import { campusService } from '../services/campusService';

vi.mock('../services/campusService');

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useCampus hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('useCampuses and campus mutations', async () => {
    vi.mocked(campusService.getCampuses).mockResolvedValue([{ id: 'c1', name: 'Campus 1' }]);
    vi.mocked(campusService.createCampus).mockResolvedValue({ id: 'c2', name: 'Campus 2' });
    vi.mocked(campusService.updateCampus).mockResolvedValue();
    vi.mocked(campusService.deleteCampus).mockResolvedValue();

    const wrapper = createWrapper();
    const { result } = renderHook(() => useCampuses(), { wrapper });
    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(result.current.data).toEqual([{ id: 'c1', name: 'Campus 1' }]);

    const { result: createHook } = renderHook(() => useCreateCampus(), { wrapper });
    await act(async () => {
      await createHook.current.mutateAsync({ name: 'Campus 2' });
    });
    expect(campusService.createCampus).toHaveBeenCalledWith({ name: 'Campus 2' });

    const { result: updateHook } = renderHook(() => useUpdateCampus(), { wrapper });
    await act(async () => {
      await updateHook.current.mutateAsync({ id: 'c1', payload: { name: 'Campus 1 Updated' } });
    });
    expect(campusService.updateCampus).toHaveBeenCalled();

    const { result: deleteHook } = renderHook(() => useDeleteCampus(), { wrapper });
    await act(async () => {
      await deleteHook.current.mutateAsync('c1');
    });
    expect(campusService.deleteCampus).toHaveBeenCalledWith('c1');
  });

  it('useBuildingLocations, useSearchRooms, useStructures, useBuildingRooms', async () => {
    vi.mocked(campusService.getBuildingLocations).mockResolvedValue([]);
    vi.mocked(campusService.searchRooms).mockResolvedValue([]);
    vi.mocked(campusService.getStructures).mockResolvedValue([]);
    vi.mocked(campusService.getBuildingRooms).mockResolvedValue([]);

    const wrapper = createWrapper();
    const { result: blHook } = renderHook(() => useBuildingLocations('c1'), { wrapper });
    await waitFor(() => expect(blHook.current.isSuccess).toBe(true));

    const { result: srHook } = renderHook(() => useSearchRooms('auditorio'), { wrapper });
    await waitFor(() => expect(srHook.current.isSuccess).toBe(true));

    const { result: stHook } = renderHook(() => useStructures('c1'), { wrapper });
    await waitFor(() => expect(stHook.current.isSuccess).toBe(true));

    const { result: brHook } = renderHook(() => useBuildingRooms('b1'), { wrapper });
    await waitFor(() => expect(brHook.current.isSuccess).toBe(true));
  });

  it('room mutations', async () => {
    vi.mocked(campusService.createRoom).mockResolvedValue({ id: 'r1', name: 'Room 1', buildingId: 'b1' });
    vi.mocked(campusService.updateRoom).mockResolvedValue();
    vi.mocked(campusService.deleteRoom).mockResolvedValue();

    const wrapper = createWrapper();
    const { result: createHook } = renderHook(() => useCreateRoom(), { wrapper });
    await act(async () => {
      await createHook.current.mutateAsync({ name: 'Room 1', buildingId: 'b1' });
    });
    expect(campusService.createRoom).toHaveBeenCalled();

    const { result: updateHook } = renderHook(() => useUpdateRoom(), { wrapper });
    await act(async () => {
      await updateHook.current.mutateAsync({ id: 'r1', payload: { name: 'R1 updated', buildingId: 'b1' } });
    });
    expect(campusService.updateRoom).toHaveBeenCalled();

    const { result: deleteHook } = renderHook(() => useDeleteRoom('b1'), { wrapper });
    await act(async () => {
      await deleteHook.current.mutateAsync('r1');
    });
    expect(campusService.deleteRoom).toHaveBeenCalledWith('r1');
  });

  it('building and structure mutations', async () => {
    vi.mocked(campusService.createBuilding).mockResolvedValue({ id: 'b1', name: 'B1', campusId: 'c1', location: { latitude: 0, longitude: 0 }, isSuspended: false });
    vi.mocked(campusService.updateBuilding).mockResolvedValue();
    vi.mocked(campusService.deleteBuilding).mockResolvedValue();
    vi.mocked(campusService.createStructure).mockResolvedValue({ id: 's1', name: 'S1', categoryId: 'cat1', latitude: 0, longitude: 0, buildingId: 'b1' });
    vi.mocked(campusService.updateStructure).mockResolvedValue();
    vi.mocked(campusService.deleteStructure).mockResolvedValue();

    const wrapper = createWrapper();
    const { result: cb } = renderHook(() => useCreateBuilding(), { wrapper });
    await act(async () => {
      await cb.current.mutateAsync({ name: 'B1', campusId: 'c1', location: { latitude: 0, longitude: 0 } });
    });

    const { result: ub } = renderHook(() => useUpdateBuilding(), { wrapper });
    await act(async () => {
      await ub.current.mutateAsync({ id: 'b1', payload: { name: 'B1 updated' } });
    });

    const { result: db } = renderHook(() => useDeleteBuilding(), { wrapper });
    await act(async () => {
      await db.current.mutateAsync('b1');
    });

    const { result: cs } = renderHook(() => useCreateStructure(), { wrapper });
    await act(async () => {
      await cs.current.mutateAsync({ name: 'S1', categoryId: 'cat1', latitude: 0, longitude: 0 });
    });

    const { result: us } = renderHook(() => useUpdateStructure(), { wrapper });
    await act(async () => {
      await us.current.mutateAsync({ id: 's1', payload: { name: 'S1 updated' } });
    });

    const { result: ds } = renderHook(() => useDeleteStructure(), { wrapper });
    await act(async () => {
      await ds.current.mutateAsync('s1');
    });
    expect(campusService.deleteStructure).toHaveBeenCalledWith('s1');
  });

  it('categories queries and mutations', async () => {
    vi.mocked(campusService.getCategories).mockResolvedValue([{ id: 'cat1', name: 'Cat 1', color: 'blue', icon: 'icon' }]);
    vi.mocked(campusService.createCategory).mockResolvedValue({ id: 'cat2', name: 'Cat 2', color: 'yellow', icon: 'icon' });
    vi.mocked(campusService.updateCategory).mockResolvedValue();
    vi.mocked(campusService.reorderCategories).mockResolvedValue();
    vi.mocked(campusService.deleteCategory).mockResolvedValue();

    const wrapper = createWrapper();
    const { result: cats } = renderHook(() => useCategories(), { wrapper });
    await waitFor(() => expect(cats.current.isSuccess).toBe(true));

    const { result: cc } = renderHook(() => useCreateCategory(), { wrapper });
    await act(async () => {
      await cc.current.mutateAsync({ name: 'Cat 2', color: 'yellow', icon: 'icon' });
    });

    const { result: uc } = renderHook(() => useUpdateCategory(), { wrapper });
    await act(async () => {
      await uc.current.mutateAsync({ id: 'cat1', payload: { name: 'Cat 1 update' } });
    });

    const { result: rc } = renderHook(() => useReorderCategories(), { wrapper });
    await act(async () => {
      await rc.current.mutateAsync([{ id: 'cat1', order: 1 }]);
    });

    const { result: dc } = renderHook(() => useDeleteCategory(), { wrapper });
    await act(async () => {
      await dc.current.mutateAsync('cat1');
    });
    expect(campusService.deleteCategory).toHaveBeenCalledWith('cat1');
  });
});
