import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MeetingStatusSelect } from './MeetingStatusSelect';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import type { MeetingDto } from '../../dtos/schedule/MeetingDto';

const mockUpdateStatus = vi.fn();
vi.mock('../../hooks/useSchedule', () => ({
  useUpdateMeetingStatus: () => ({
    mutate: mockUpdateStatus,
    isPending: false,
  }),
}));

describe('MeetingStatusSelect', () => {
  const meeting: MeetingDto = {
    id: 'm1',
    teacherRefId: 't1',
    studentRefId: 's1',
    scheduledAt: '2026-11-03T10:00:00Z',
    durationMinutes: 30,
    status: 'Pending',
    structureRefId: 'st1',
  };

  it('renders select and changes status when teacher confirms', () => {
    renderWithQueryClient(
      <MeetingStatusSelect meeting={meeting} isTeacher={true} isStudent={false} />,
    );

    const trigger = screen.getAllByRole('button')[0];
    fireEvent.click(trigger);

    const confirmOption = screen.getByText('Confirmada');
    fireEvent.click(confirmOption);

    expect(mockUpdateStatus).toHaveBeenCalledWith({
      id: 'm1',
      status: 'Confirmed',
    });
  });
});
