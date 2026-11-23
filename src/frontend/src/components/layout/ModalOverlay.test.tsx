import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ModalOverlay } from './ModalOverlay';

describe('ModalOverlay', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    document.body.style.overflow = '';
    vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
      callback(0);
      return 1;
    });
    vi.spyOn(window, 'cancelAnimationFrame').mockImplementation(() => undefined);
  });

  it('renders nothing when closed', () => {
    render(
      <ModalOverlay isOpen={false} onClose={vi.fn()}>
        <button type="button">Contenido</button>
      </ModalOverlay>,
    );

    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(document.body.style.overflow).toBe('');
  });

  it('renders children in a portal, focuses the first focusable element and locks scroll', () => {
    const { container } = render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Primero</button>
        <button type="button">Último</button>
      </ModalOverlay>,
    );

    expect(screen.getByRole('dialog')).toBeInTheDocument();
    expect(container).not.toContainElement(screen.getByText('Primero'));
    expect(screen.getByText('Primero')).toHaveFocus();
    expect(document.body.style.overflow).toBe('hidden');
  });

  it('focuses the dialog container when there are no focusable elements', () => {
    render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <p>Sin controles</p>
      </ModalOverlay>,
    );

    expect(screen.getByRole('dialog')).toHaveFocus();
  });

  it('closes on Escape and on backdrop click, but not on inner click', () => {
    const onClose = vi.fn();

    render(
      <ModalOverlay isOpen onClose={onClose}>
        <button type="button">Dentro</button>
      </ModalOverlay>,
    );

    const dialog = screen.getByRole('dialog');
    const backdrop = dialog.parentElement as HTMLElement;

    fireEvent.click(dialog);
    expect(onClose).not.toHaveBeenCalled();

    fireEvent.click(backdrop);
    expect(onClose).toHaveBeenCalledTimes(1);

    fireEvent.keyDown(document, { key: 'Escape' });
    expect(onClose).toHaveBeenCalledTimes(2);
  });

  it('cycles focus forward and backward with Tab', () => {
    render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Primero</button>
        <button type="button">Último</button>
      </ModalOverlay>,
    );

    const first = screen.getByText('Primero');
    const last = screen.getByText('Último');

    last.focus();
    fireEvent.keyDown(document, { key: 'Tab' });
    expect(first).toHaveFocus();

    first.focus();
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true });
    expect(last).toHaveFocus();
  });

  it('brings focus inside when Tab is pressed while focus is outside', () => {
    const outside = document.createElement('button');
    outside.textContent = 'Fuera';
    document.body.appendChild(outside);
    outside.focus();

    render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Primero</button>
        <button type="button">Último</button>
      </ModalOverlay>,
    );

    const first = screen.getByText('Primero');
    const last = screen.getByText('Último');

    fireEvent.keyDown(document, { key: 'Tab' });
    expect(first).toHaveFocus();

    outside.focus();
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true });
    expect(last).toHaveFocus();

    outside.remove();
  });

  it('keeps focus in the dialog when Tab is pressed with no focusable elements', () => {
    render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <p>Sin controles</p>
      </ModalOverlay>,
    );

    const dialog = screen.getByRole('dialog');
    fireEvent.keyDown(document, { key: 'Tab' });
    expect(dialog).toHaveFocus();
  });

  it('restores focus and unlocks scroll when closed', () => {
    const outside = document.createElement('button');
    outside.textContent = 'Fuera';
    document.body.appendChild(outside);
    outside.focus();

    const { rerender } = render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Dentro</button>
      </ModalOverlay>,
    );

    expect(document.body.style.overflow).toBe('hidden');

    rerender(
      <ModalOverlay isOpen={false} onClose={vi.fn()}>
        <button type="button">Dentro</button>
      </ModalOverlay>,
    );

    expect(document.body.style.overflow).toBe('');
    expect(outside).toHaveFocus();

    outside.remove();
  });

  it('keeps the scroll lock while another overlay is still open', () => {
    const first = render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Uno</button>
      </ModalOverlay>,
    );
    const second = render(
      <ModalOverlay isOpen onClose={vi.fn()}>
        <button type="button">Dos</button>
      </ModalOverlay>,
    );

    expect(document.body.style.overflow).toBe('hidden');

    first.unmount();
    expect(document.body.style.overflow).toBe('hidden');

    second.unmount();
    expect(document.body.style.overflow).toBe('');
  });
});
