import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor, act } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  useReports,
  useReport,
  useCreateReport,
  useUpdateReportStatus,
  useDeleteReport,
} from './useReports';
import { incidentService } from '../services/incidentService';
import { TicketStatus } from '../constants/ticketStatus';
import type { ReportPageDto } from '../dtos/incident/reports/ReportPageDto';
import type { ReportDto } from '../dtos/incident/reports/ReportDto';

vi.mock('../services/incidentService');

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
};

describe('useReports hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('useReports and useReport queries', async () => {
    vi.mocked(incidentService.searchReports).mockResolvedValue({ items: [], totalPages: 1 } as unknown as ReportPageDto);
    vi.mocked(incidentService.getReport).mockResolvedValue({ id: 'r1', title: 'Rep 1' } as unknown as ReportDto);

    const wrapper = createWrapper();
    const { result: reportsHook } = renderHook(() => useReports({ page: 1 }), { wrapper });
    await waitFor(() => expect(reportsHook.current.isSuccess).toBe(true));
    expect(reportsHook.current.data?.totalPages).toBe(1);

    const { result: reportHook } = renderHook(() => useReport('r1'), { wrapper });
    await waitFor(() => expect(reportHook.current.isSuccess).toBe(true));
    expect(reportHook.current.data?.id).toBe('r1');
  });

  it('report mutations: create, update, delete', async () => {
    vi.mocked(incidentService.createReport).mockResolvedValue('r1');
    vi.mocked(incidentService.updateReportStatus).mockResolvedValue();
    vi.mocked(incidentService.deleteReport).mockResolvedValue();

    const wrapper = createWrapper();
    const { result: createHook } = renderHook(() => useCreateReport(), { wrapper });
    await act(async () => {
      await createHook.current.mutateAsync({ title: 'New', description: 'Desc', ticketType: TicketStatus.Pending });
    });
    expect(incidentService.createReport).toHaveBeenCalled();

    const { result: updateHook } = renderHook(() => useUpdateReportStatus(), { wrapper });
    await act(async () => {
      await updateHook.current.mutateAsync({ id: 'r1', status: TicketStatus.Resolved });
    });
    expect(incidentService.updateReportStatus).toHaveBeenCalledWith('r1', TicketStatus.Resolved, undefined);

    const { result: deleteHook } = renderHook(() => useDeleteReport(), { wrapper });
    await act(async () => {
      await deleteHook.current.mutateAsync('r1');
    });
    expect(incidentService.deleteReport).toHaveBeenCalledWith('r1');
  });
});
