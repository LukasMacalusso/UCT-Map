import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ScheduleView as TeacherView } from './TeacherView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

vi.mock('../hooks/useSchedule', () => ({
  useTeacherWorkload: () => ({
    data: {
      teacherId: 't1',
      weeklyHours: 12,
      officeHours: [
        {
          id: 'oh1',
          dayOfWeek: 'Monday',
          startTime: '09:00:00',
          endTime: '11:00:00',
          structureRefId: 'st1',
        },
      ],
      meetings: [
        {
          id: 'm1',
          teacherRefId: 't1',
          studentRefId: 's1',
          scheduledAt: '2026-11-03T10:00:00Z',
          durationMinutes: 30,
          status: 'Confirmed',
          structureRefId: 'st1',
        },
      ],
    },
    isLoading: false,
    refetch: vi.fn(),
  }),
  useUpdateMeetingStatus: () => ({
    mutate: vi.fn(),
    isPending: false,
  }),
}));

vi.mock('../hooks/useCampus', () => ({
  useStructures: () => ({
    data: [{ id: 'st1', name: 'Oficina 301' }],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: [{ id: 's1', name: 'Estudiante Juan', email: 'juan@uct.cl' }],
    isLoading: false,
  }),
}));

describe('TeacherView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Teacher);
  });

  it('renders teacher workload, schedule and meetings', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <TeacherView />
      </MemoryRouter>,
    );

    expect(screen.getByText('Mis Bloques de Atención')).toBeInTheDocument();
    expect(screen.getByText('Reuniones Agendadas')).toBeInTheDocument();
    expect(screen.getByText(/Estudiante Juan/i)).toBeInTheDocument();
    expect(screen.getAllByText('Oficina 301').length).toBeGreaterThan(0);
  });
});
