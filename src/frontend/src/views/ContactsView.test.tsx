import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ContactsView } from './ContactsView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

vi.mock('../hooks/useUsers', () => ({
  useUsers: () => ({
    data: [
      {
        id: 'u1',
        name: 'Profesor Carlos',
        email: 'carlos@uct.cl',
        role: Role.Teacher,
        isSuspended: false,
      },
    ],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Oficina 101', campusId: 'c1' }],
    isLoading: false,
  }),
}));

vi.mock('../hooks/useSchedule', () => ({
  useOfficeHours: () => ({
    data: [
      {
        id: 'oh1',
        teacherId: 'u1',
        dayOfWeek: 'Monday',
        startTime: '09:00:00',
        endTime: '11:00:00',
        structureRefId: 's1',
      },
    ],
    isLoading: false,
  }),
  useTeacherAvailability: () => ({
    data: { teacherId: 'u1', isAvailable: true },
    isLoading: false,
  }),
  useTeacherMeetings: () => ({
    data: [],
    isLoading: false,
  }),
  useCreateMeeting: () => ({
    mutate: vi.fn(),
    isPending: false,
    reset: vi.fn(),
  }),
}));

describe('ContactsView', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Student);
  });

  it('renders contact list, filters by search, and opens contact profile modal', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <ContactsView />
      </MemoryRouter>,
    );

    expect(screen.getAllByText('Profesor Carlos').length).toBeGreaterThan(0);

    const infoBtn = screen.getByRole('button', { name: /info/i });
    fireEvent.click(infoBtn);

    expect(screen.getByText('Atención Estudiantes')).toBeInTheDocument();
  });
});
