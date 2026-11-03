import { describe, it, expect, vi } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { BuildingFormModal } from './BuildingFormModal';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';

describe('BuildingFormModal', () => {
  it('updates the preview while editing and closes with both actions', () => {
    const onClose = vi.fn();

    renderWithQueryClient(<BuildingFormModal onClose={onClose} />);

    expect(screen.getByText('Editar Edificio')).toBeInTheDocument();
    expect(screen.getByText('Previsualización')).toBeInTheDocument();

    const titleInput = screen.getByDisplayValue('NUEVO EDIFICIO');
    fireEvent.change(titleInput, { target: { value: 'Edificio Nuevo' } });

    expect(screen.getByDisplayValue('Edificio Nuevo')).toBeInTheDocument();
    expect(screen.getAllByText('Edificio Nuevo').length).toBeGreaterThan(0);

    const servicesInput = screen.getByDisplayValue('WIFI, BAÑOS');
    fireEvent.change(servicesInput, { target: { value: 'WIFI, BAÑOS, CAFÉ' } });

    fireEvent.click(screen.getByRole('button', { name: /guardar/i }));
    expect(onClose).toHaveBeenCalledTimes(1);

    fireEvent.click(screen.getByRole('button', { name: /cancelar/i }));
    expect(onClose).toHaveBeenCalledTimes(2);
  });
});
