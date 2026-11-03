import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ShowcaseView } from './ShowcaseView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';

vi.mock('../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Edificio A', campusId: 'c1' }],
    isLoading: false,
  }),
  useBuildingRooms: () => ({
    data: [{ id: 'r1', name: 'Sala 101', floor: 1, number: '101' }],
    isLoading: false,
  }),
}));

describe('ShowcaseView', () => {
  it('renders showcase of all UI components without crashing and handles interactions', () => {
    vi.useFakeTimers();
    const alertMock = vi.spyOn(window, 'alert').mockImplementation(() => {});

    renderWithQueryClient(
      <MemoryRouter>
        <ShowcaseView />
      </MemoryRouter>,
    );

    expect(screen.getByText('María González Pérez')).toBeInTheDocument();
    expect(screen.getByText('NOMBRE PROFESOR')).toBeInTheDocument();

    // Toggle filter item
    const bibliotecaCheckbox = screen.getByLabelText(/biblioteca/i);
    fireEvent.click(bibliotecaCheckbox);

    // Search input change
    const searchInput = screen.getByPlaceholderText(/escribe 'patata'/i);
    fireEvent.change(searchInput, { target: { value: 'patata' } });
    expect(searchInput).toHaveValue('patata');

    // TimedActionCard buttons
    act(() => {
      vi.advanceTimersByTime(5100);
    });

    const confirmBtn = screen.getByText('Confirmar');
    fireEvent.click(confirmBtn);
    expect(alertMock).toHaveBeenCalledWith('Confirmado!');

    const cancelBtn = screen.getAllByText('Cancelar')[0];
    fireEvent.click(cancelBtn);
    expect(alertMock).toHaveBeenCalledWith('Cancelado!');

    alertMock.mockRestore();
    vi.useRealTimers();
  });
});
