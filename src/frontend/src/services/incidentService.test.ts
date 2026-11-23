import { describe, it, expect, vi, beforeEach } from 'vitest';
import { incidentService } from './incidentService';
import httpClient from '../api/httpClient';
import { TicketStatus } from '../constants/ticketStatus';
import { LostObjectStatus } from '../constants/lostObjectsStatus';

vi.mock('../api/httpClient');

describe('incidentService', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('reports', () => {
    it('searchReports calls GET /api/incident/reports', async () => {
      vi.mocked(httpClient.get).mockResolvedValueOnce({ data: { items: [], totalPages: 1 } });
      const res = await incidentService.searchReports({ page: 1 });
      expect(res.totalPages).toBe(1);
    });

    it('getReport calls GET /api/incident/reports/:id', async () => {
      vi.mocked(httpClient.get).mockResolvedValueOnce({ data: { id: 'r1' } });
      const res = await incidentService.getReport('r1');
      expect(res.id).toBe('r1');
    });

    it('createReport calls POST /api/incident/reports', async () => {
      vi.mocked(httpClient.post).mockResolvedValueOnce({ data: { id: 'new-r1' } });
      const res = await incidentService.createReport({
        title: 'Title',
        description: 'Desc',
        ticketType: TicketStatus.Pending,
      });
      expect(res).toBe('new-r1');
    });

    it('updateReportStatus and deleteReport', async () => {
      vi.mocked(httpClient.patch).mockResolvedValueOnce({ data: {} });
      await incidentService.updateReportStatus('r1', TicketStatus.Resolved);
      expect(httpClient.patch).toHaveBeenCalledWith('/api/incident/reports/r1/report/status', {
        status: TicketStatus.Resolved,
        complainStatus: undefined,
      });

      vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
      await incidentService.deleteReport('r1');
      expect(httpClient.delete).toHaveBeenCalledWith('/api/incident/reports/r1');
    });
  });

  describe('lost objects', () => {
    it('searchLostObjects maps and enriches items with userRefId', async () => {
      vi.mocked(httpClient.get)
        .mockResolvedValueOnce({
          data: {
            items: [{ id: 'lo1', title: 'Lost watch', status: 'Pending', createdAt: '2026-11-03' }],
            totalPages: 1,
          },
        })
        .mockResolvedValueOnce({
          data: {
            items: [{ userRefId: 'author-123' }],
          },
        });

      const res = await incidentService.searchLostObjects();
      expect(res.items.length).toBe(1);
      expect(res.items[0].userRefId).toBe('author-123');
    });

    it('getLostObject fetches object and enriches author', async () => {
      vi.mocked(httpClient.get)
        .mockResolvedValueOnce({
          data: { id: 'lo1', title: 'Lost item' },
        })
        .mockResolvedValueOnce({
          data: { items: [{ userRefId: 'user-99' }] },
        });

      const res = await incidentService.getLostObject('lo1');
      expect(res.userRefId).toBe('user-99');
    });

    it('createLostObject calls POST and links to ticket report', async () => {
      vi.mocked(httpClient.post)
        .mockResolvedValueOnce({ data: { id: 'lo-created' } })
        .mockResolvedValueOnce({ data: { id: 'ticket-created' } });

      const res = await incidentService.createLostObject({
        title: 'Keys',
        description: 'Car keys',
        structureId: 'st-1',
      });
      expect(res).toBe('lo-created');
      expect(httpClient.post).toHaveBeenCalledTimes(2);
    });

    it('updateLostObjectStatus and deleteLostObject', async () => {
      vi.mocked(httpClient.patch).mockResolvedValueOnce({ data: {} });
      await incidentService.updateLostObjectStatus('lo1', LostObjectStatus.Resolved);
      expect(httpClient.patch).toHaveBeenCalledWith('/api/incident/lost-objects/lo1/lost/status', {
        status: LostObjectStatus.Resolved,
      });

      vi.mocked(httpClient.delete).mockResolvedValueOnce({ data: {} });
      await incidentService.deleteLostObject('lo1');
      expect(httpClient.delete).toHaveBeenCalledWith('/api/incident/lost-objects/lo1');
    });
  });
});
