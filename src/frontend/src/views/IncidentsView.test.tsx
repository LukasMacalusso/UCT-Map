import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { IncidentsView } from './IncidentsView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import { TicketStatus } from '../constants/ticketStatus';

vi.mock('../hooks/useReports', () => ({
  useReports: () => ({
    data: {
      items: [
        {
          id: 'r1',
          ticketType: TicketStatus.Pending,
          structureRefId: 's1',
          reportedAt: '2026-11-03T10:00:00Z',
          userRefId: 'u1',
          complaintDetails: {
            title: 'Proyector dañado',
            description: 'No enciende la lámpara',
          },
        },
      ],
      totalPages: 1,
    },
    isLoading: false,
  }),
  useCreateReport: () => ({
    mutateAsync: vi.fn(),
    isPending: false,
    reset: vi.fn(),
  }),
  useUpdateReportStatus: () => ({
    mutate: vi.fn(),
    isPending: false,
  }),
}));

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Auditorio', campusId: 'c1' }],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: [{ id: 'u1', name: 'Lucas', email: 'lucas@uct.cl' }],
    isLoading: false,
  }),
}));

describe('IncidentsView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Admin);
  });

  it('renders incidents and allows opening report creation modal', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <IncidentsView />
      </MemoryRouter>,
    );

    expect(screen.getByText('Proyector dañado')).toBeInTheDocument();
    expect(screen.getByText(/"No enciende la lámpara"/i)).toBeInTheDocument();

    const reportBtn = screen.getByRole('button', { name: /publicar/i });
    fireEvent.click(reportBtn);

    expect(screen.getByText('PUBLICAR REPORTE')).toBeInTheDocument();
  });

  it('filters reports by campus when campus is selected', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <IncidentsView />
      </MemoryRouter>,
    );

    expect(screen.getByText('Proyector dañado')).toBeInTheDocument();

    // The Select component renders a trigger button and a list of options
    const triggers = screen.getAllByRole('button', { name: /todos los campus/i });
    fireEvent.click(triggers[0]);

    const campusOption = screen.getByRole('button', { name: 'Campus San Juan' });
    fireEvent.click(campusOption);

    // Matches the structure 's1' which has campusId 'c1'
    expect(screen.getByText('Proyector dañado')).toBeInTheDocument();
  });
});
