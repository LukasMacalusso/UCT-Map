import { render, screen, fireEvent, act } from '@testing-library/react';
import { describe, it, expect, vi, afterEach } from 'vitest';
import { UserManagementCard } from './UserManagementCard';
import { Role } from '../../constants/role';

const baseProps = {
  id: 'u1',
  name: 'Ana Torres',
  email: 'ana@uct.cl',
  role: Role.Student,
};

afterEach(() => {
  vi.useRealTimers();
});

describe('UserManagementCard', () => {
  it('muestra el nombre y el correo del usuario', () => {
    render(<UserManagementCard {...baseProps} />);
    expect(screen.getByText('Ana Torres')).toBeInTheDocument();
    expect(screen.getByText('ana@uct.cl')).toBeInTheDocument();
  });

  it('solo muestra el tag "Suspendido" cuando la cuenta está suspendida', () => {
    const { rerender } = render(<UserManagementCard {...baseProps} isSuspended={false} />);
    expect(screen.queryByText('Suspendido')).not.toBeInTheDocument();

    rerender(<UserManagementCard {...baseProps} isSuspended={true} />);
    expect(screen.getByText('Suspendido')).toBeInTheDocument();
  });

  it('deshabilita el botón de suspensión si canToggleSuspension es false', () => {
    render(<UserManagementCard {...baseProps} canToggleSuspension={false} />);
    const button = screen.getByRole('button', { name: 'Suspender' });
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute('title', 'No puedes suspender tu propia cuenta');
  });

  it('pide confirmación antes de suspender y llama al handler al confirmar', () => {
    vi.useFakeTimers();
    const onToggleSuspension = vi.fn();
    render(<UserManagementCard {...baseProps} onToggleSuspension={onToggleSuspension} />);

    fireEvent.click(screen.getByRole('button', { name: 'Suspender' }));

    expect(screen.getByText('Suspender cuenta')).toBeInTheDocument();
    expect(onToggleSuspension).not.toHaveBeenCalled();

    const confirm = screen.getByRole('button', { name: 'Sí, suspender' });
    expect(confirm).toBeDisabled();

    act(() => {
      vi.advanceTimersByTime(3200);
    });

    fireEvent.click(confirm);
    expect(onToggleSuspension).toHaveBeenCalledWith('u1', true);
  });

  it('no llama al handler si se cancela la confirmación', () => {
    vi.useFakeTimers();
    const onToggleSuspension = vi.fn();
    render(<UserManagementCard {...baseProps} onToggleSuspension={onToggleSuspension} />);

    fireEvent.click(screen.getByRole('button', { name: 'Suspender' }));

    act(() => {
      vi.advanceTimersByTime(3200);
    });

    fireEvent.click(screen.getByRole('button', { name: 'Cancelar' }));

    expect(onToggleSuspension).not.toHaveBeenCalled();
    expect(screen.queryByText('Suspender cuenta')).not.toBeInTheDocument();
  });

  it('llama a onViewProfile con el id al hacer click en "Ver perfil"', () => {
    const onViewProfile = vi.fn();
    render(<UserManagementCard {...baseProps} onViewProfile={onViewProfile} />);

    fireEvent.click(screen.getByRole('button', { name: 'Ver perfil' }));

    expect(onViewProfile).toHaveBeenCalledWith('u1');
  });
});
