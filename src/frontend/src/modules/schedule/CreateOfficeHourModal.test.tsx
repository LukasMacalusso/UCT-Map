import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { CreateOfficeHourModal } from './CreateOfficeHourModal';
import type { StructureDto } from '../../dtos/campus/StructureDto';

const state = vi.hoisted(() => ({
  mutate: vi.fn(),
  reset: vi.fn(),
  isPending: false,
  error: null as { message?: string } | null,
}));

vi.mock('../../hooks/useSchedule', () => ({
  useCreateOfficeHour: () => state,
}));

const structures: StructureDto[] = [
  {
    id: 'st1',
    campusId: 'c1',
    name: 'Oficina 301',
    latitude: -38.7,
    longitude: -72.6,
  },
];

const renderModal = (teacherRefId: string | undefined = 't1') => {
  const onClose = vi.fn();
  render(
    <CreateOfficeHourModal
      isOpen
      onClose={onClose}
      teacherRefId={teacherRefId}
      structures={structures}
    />,
  );
  return { onClose };
};

describe('CreateOfficeHourModal', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    state.isPending = false;
    state.error = null;
  });

  it('submits the default block and closes on success', () => {
    state.mutate.mockImplementation((...args: unknown[]) => {
      const options = args[1] as { onSuccess?: () => void } | undefined;
      options?.onSuccess?.();
    });
    const { onClose } = renderModal();

    fireEvent.click(screen.getByRole('button', { name: /guardar bloque/i }));

    expect(state.mutate).toHaveBeenCalledWith(
      {
        teacherRefId: 't1',
        structureRefId: null,
        dayOfWeek: 'Monday',
        startTime: '09:00:00',
        endTime: '10:00:00',
      },
      expect.objectContaining({ onSuccess: expect.any(Function) }),
    );
    expect(onClose).toHaveBeenCalled();
  });

  it('submits the selected day, structure and times', () => {
    renderModal();

    fireEvent.click(screen.getAllByRole('button', { name: 'Lunes' })[0]);
    fireEvent.click(screen.getByRole('button', { name: 'Martes' }));
    fireEvent.click(screen.getAllByRole('button', { name: 'Sin ubicación' })[0]);
    fireEvent.click(screen.getByRole('button', { name: 'Oficina 301' }));
    fireEvent.change(screen.getByLabelText('Hora de inicio'), {
      target: { value: '11:30' },
    });
    fireEvent.change(screen.getByLabelText('Hora de fin'), {
      target: { value: '13:15' },
    });
    fireEvent.click(screen.getByRole('button', { name: /guardar bloque/i }));

    expect(state.mutate).toHaveBeenCalledWith(
      {
        teacherRefId: 't1',
        structureRefId: 'st1',
        dayOfWeek: 'Tuesday',
        startTime: '11:30:00',
        endTime: '13:15:00',
      },
      expect.objectContaining({ onSuccess: expect.any(Function) }),
    );
  });

  it('rejects an end time before the start time', () => {
    renderModal();

    fireEvent.change(screen.getByLabelText('Hora de fin'), {
      target: { value: '08:00' },
    });
    fireEvent.click(screen.getByRole('button', { name: /guardar bloque/i }));

    expect(
      screen.getByText('La hora de fin debe ser posterior a la hora de inicio.'),
    ).toBeInTheDocument();
    expect(state.mutate).not.toHaveBeenCalled();
  });

  it('requires both times', () => {
    renderModal();

    fireEvent.change(screen.getByLabelText('Hora de inicio'), {
      target: { value: '' },
    });
    fireEvent.click(screen.getByRole('button', { name: /guardar bloque/i }));

    expect(
      screen.getByText('Debes indicar la hora de inicio y de fin.'),
    ).toBeInTheDocument();
    expect(state.mutate).not.toHaveBeenCalled();
  });

  it('shows the mutation error and pending state', () => {
    state.error = { message: 'Error del servidor' };
    const { unmount } = render(
      <CreateOfficeHourModal
        isOpen
        onClose={vi.fn()}
        teacherRefId="t1"
        structures={structures}
      />,
    );

    expect(screen.getByText('Error del servidor')).toBeInTheDocument();
    unmount();

    state.error = null;
    state.isPending = true;
    render(
      <CreateOfficeHourModal
        isOpen
        onClose={vi.fn()}
        teacherRefId="t1"
        structures={structures}
      />,
    );

    expect(screen.getByRole('button', { name: /guardando/i })).toBeDisabled();
  });

  it('blocks submission when the teacher cannot be identified', () => {
    renderModal('');

    expect(
      screen.getByText('No se pudo identificar al profesor. Vuelve a iniciar sesión.'),
    ).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /guardar bloque/i })).toBeDisabled();

    fireEvent.submit(screen.getByRole('dialog').querySelector('form')!);

    expect(state.mutate).not.toHaveBeenCalled();
  });

  it('closes from the cancel button and the header button', () => {
    const { onClose } = renderModal();

    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }));
    expect(onClose).toHaveBeenCalledTimes(1);
    expect(state.reset).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByTitle('Cerrar'));
    expect(onClose).toHaveBeenCalledTimes(2);
  });

  it('does not render when closed', () => {
    render(
      <CreateOfficeHourModal
        isOpen={false}
        onClose={vi.fn()}
        teacherRefId="t1"
        structures={structures}
      />,
    );

    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
