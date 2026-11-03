import { describe, it, expect, vi, beforeEach } from 'vitest';
import { campusService } from './campusService';
import httpClient from '../api/httpClient';

vi.mock('../api/httpClient');

describe('campusService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('getCampuses calls GET /api/campus/campuses', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [{ id: '1', name: 'Norte' }] });
    const res = await campusService.getCampuses();
    expect(res).toEqual([{ id: '1', name: 'Norte' }]);
  });

  it('createCampus calls POST /api/campus/campuses', async () => {
    const payload = { name: 'Campus San Juan' };
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'c1', ...payload } });
    const res = await campusService.createCampus(payload);
    expect(res.id).toBe('c1');
  });

  it('updateCampus and deleteCampus', async () => {
    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });

    await campusService.updateCampus('c1', { name: 'Updated' });
    expect(httpClient.put).toHaveBeenCalledWith('/api/campus/campuses/c1', { name: 'Updated' });

    await campusService.deleteCampus('c1');
    expect(httpClient.delete).toHaveBeenCalledWith('/api/campus/campuses/c1');
  });

  it('getBuildingLocations with and without campusId', async () => {
    vi.mocked(httpClient.get).mockResolvedValue({ data: [] });
    await campusService.getBuildingLocations();
    expect(httpClient.get).toHaveBeenCalledWith('/api/campus/buildings/locations', { params: undefined });

    await campusService.getBuildingLocations('c1');
    expect(httpClient.get).toHaveBeenCalledWith('/api/campus/buildings/locations', { params: { campusId: 'c1' } });
  });

  it('searchRooms returns empty array on empty term', async () => {
    const res = await campusService.searchRooms('   ');
    expect(res).toEqual([]);
    expect(httpClient.get).not.toHaveBeenCalled();
  });

  it('searchRooms performs search when term provided', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [{ id: 'r1', name: 'Lab 1' }] });
    const res = await campusService.searchRooms('lab');
    expect(res).toEqual([{ id: 'r1', name: 'Lab 1' }]);
  });

  it('handles rooms CRUD', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [] });
    await campusService.getBuildingRooms('b1');
    expect(httpClient.get).toHaveBeenCalledWith('/api/campus/buildings/b1/rooms');

    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'r1' } });
    await campusService.createRoom({ name: 'R1', buildingId: 'b1' });
    expect(httpClient.post).toHaveBeenCalled();

    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    await campusService.updateRoom('r1', { name: 'R1 updated' });
    expect(httpClient.put).toHaveBeenCalled();

    vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
    await campusService.deleteRoom('r1');
    expect(httpClient.delete).toHaveBeenCalled();
  });

  it('handles structures CRUD', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [] });
    await campusService.getStructures('c1');
    expect(httpClient.get).toHaveBeenCalledWith('/api/campus/structures', { params: { campusId: 'c1' } });

    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 's1' } });
    await campusService.createStructure({ name: 'S1', categoryId: 'cat1', latitude: 0, longitude: 0 });
    expect(httpClient.post).toHaveBeenCalled();

    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    await campusService.updateStructure('s1', { name: 'S1 updated' });
    expect(httpClient.put).toHaveBeenCalled();

    vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
    await campusService.deleteStructure('s1');
    expect(httpClient.delete).toHaveBeenCalled();
  });

  it('handles buildings CRUD', async () => {
    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'b1' } });
    await campusService.createBuilding({ name: 'B1', campusId: 'c1', location: { latitude: 0, longitude: 0 } });
    expect(httpClient.post).toHaveBeenCalled();

    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    await campusService.updateBuilding('b1', { name: 'B1 updated' });
    expect(httpClient.put).toHaveBeenCalled();

    vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
    await campusService.deleteBuilding('b1');
    expect(httpClient.delete).toHaveBeenCalled();
  });

  it('handles categories CRUD and reorder', async () => {
    vi.mocked(httpClient.get).mockResolvedValueOnce({ data: [] });
    await campusService.getCategories();
    expect(httpClient.get).toHaveBeenCalledWith('/api/campus/categories');

    vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'cat1' } });
    await campusService.createCategory({ name: 'Cat 1', color: 'blue', icon: 'icon' });
    expect(httpClient.post).toHaveBeenCalled();

    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    await campusService.updateCategory('cat1', { name: 'Cat 1 edit' });
    expect(httpClient.put).toHaveBeenCalledWith('/api/campus/categories/cat1', { name: 'Cat 1 edit' });

    vi.mocked(httpClient.put).mockResolvedValueOnce({ data: {} });
    await campusService.reorderCategories([{ id: 'cat1', order: 1 }]);
    expect(httpClient.put).toHaveBeenCalledWith('/api/campus/categories/reorder', [{ id: 'cat1', order: 1 }]);

    vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
    await campusService.deleteCategory('cat1');
    expect(httpClient.delete).toHaveBeenCalledWith('/api/campus/categories/cat1');
  });

  it('throws ApiError on failed request', async () => {
    vi.mocked(httpClient.get).mockRejectedValueOnce(new Error('Network fail'));
    await expect(campusService.getCampuses()).rejects.toThrow();
  });
});
