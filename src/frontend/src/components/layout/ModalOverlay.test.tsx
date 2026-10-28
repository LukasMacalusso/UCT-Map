import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, afterEach } from 'vitest';
import { ModalOverlay } from './ModalOverlay';

const renderOverlay = (isOpen = true, onClose = vi.fn()) =>
  render(
    <ModalOverlay isOpen={isOpen} onClose={onClose}>
      <div>
        <h2>Contenido modal</h2>
        <button type="button">Acción</button>
      </div>
    </ModalOverlay>
  );

afterEach(() => {
  document.body.style.overflow = '';
});

describe('ModalOverlay', () => {
  it('no renderiza nada cuando está cerrado', () => {
    renderOverlay(false);
    expect(screen.queryByText('Contenido modal')).not.toBeInTheDocument();
  });

  it('monta el modal en document.body mediante un portal', () => {
    const { container } = renderOverlay();
    expect(screen.getByText('Contenido modal')).toBeInTheDocument();
    expect(container).not.toContainElement(screen.getByText('Contenido modal'));
  });

  it('cierra al hacer click en el fondo pero no en el contenido', () => {
    const onClose = vi.fn();
    renderOverlay(true, onClose);

    const dialog = screen.getByRole('dialog');
    fireEvent.click(dialog);
    expect(onClose).not.toHaveBeenCalled();

    fireEvent.click(dialog.parentElement as HTMLElement);
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('cierra al presionar Escape', () => {
    const onClose = vi.fn();
    renderOverlay(true, onClose);

    fireEvent.keyDown(document, { key: 'Escape' });
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('bloquea el scroll del body mientras está abierto y lo restaura al cerrar', () => {
    const { rerender } = renderOverlay();

    expect(document.body.style.overflow).toBe('hidden');

    rerender(
      <ModalOverlay isOpen={false} onClose={() => {}}>
        <div>Contenido modal</div>
      </ModalOverlay>
    );

    expect(document.body.style.overflow).toBe('');
  });

  it('enfoca el primer elemento interactivo al abrirse', async () => {
    renderOverlay();

    await waitFor(() =>
      expect(screen.getByRole('button', { name: 'Acción' })).toHaveFocus()
    );
  });
});
