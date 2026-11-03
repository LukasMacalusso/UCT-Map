import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ObjectsView } from './ObjectsView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import { LostObjectStatus } from '../constants/lostObjectsStatus';

vi.mock('../hooks/useLostObjects', () => ({
  useLostObjects: () => ({
    data: {
      items: [
        {
          id: 'lo1',
          lostObjectId: 'lo1',
          title: 'Calculadora Casio',
          description: 'Encontrada en sala 204',
          status: LostObjectStatus.Pending,
          structureId: 's1',
          createdAt: '2026-11-03T10:00:00Z',
          reportedAt: '2026-11-03T10:00:00Z',
          userRefId: 'u1',
        },
      ],
      totalPages: 1,
    },
    isLoading: false,
  }),
  useCreateLostObject: () => ({
    mutateAsync: vi.fn(),
    isPending: false,
    reset: vi.fn(),
  }),
  useUpdateLostObjectStatus: () => ({
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
    data: [{ id: 's1', name: 'Sala 204', campusId: 'c1' }],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: [{ id: 'u1', name: 'Ana Gómez', email: 'ana@uct.cl' }],
    isLoading: false,
  }),
}));

describe('ObjectsView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Admin);
  });

  it('renders lost objects list and opens creation modal', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <ObjectsView />
      </MemoryRouter>,
    );

    expect(screen.getByText('Calculadora Casio')).toBeInTheDocument();
    expect(screen.getAllByText('Sala 204').length).toBeGreaterThan(0);

    const reportBtn = screen.getByRole('button', { name: /publicar/i });
    fireEvent.click(reportBtn);

    expect(screen.getByText('REPORTAR OBJETO PERDIDO')).toBeInTheDocument();
  });
});
