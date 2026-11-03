import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { NumberSelect } from './NumberSelect';

describe('NumberSelect', () => {
  it('renders with initialValue and label', () => {
    render(<NumberSelect initialValue={10} label="Cantidad" min={0} max={20} />);
    expect(screen.getByText('Cantidad')).toBeInTheDocument();
    expect(screen.getByText('10')).toBeInTheDocument();
  });

  it('increments and decrements on button clicks', () => {
    const onChange = vi.fn();
    render(<NumberSelect initialValue={5} onChange={onChange} min={0} max={10} />);

    const buttons = screen.getAllByRole('button');
    const decBtn = buttons[0];
    const incBtn = buttons[1];

    fireEvent.mouseDown(incBtn);
    expect(onChange).toHaveBeenCalledWith(6);

    fireEvent.mouseDown(decBtn);
    expect(onChange).toHaveBeenCalledWith(5);
  });

  it('respects min and max bounds', () => {
    const onChange = vi.fn();
    render(<NumberSelect initialValue={10} onChange={onChange} min={0} max={10} />);

    const buttons = screen.getAllByRole('button');
    const incBtn = buttons[1];
    fireEvent.mouseDown(incBtn);
    expect(onChange).not.toHaveBeenCalled();
  });

  it('supports float values with step multiplier', () => {
    const onChange = vi.fn();
    render(<NumberSelect initialValue={1.5} onChange={onChange} isFloat multiplier={0.5} />);

    const buttons = screen.getAllByRole('button');
    const incBtn = buttons[1];
    fireEvent.mouseDown(incBtn);
    expect(onChange).toHaveBeenCalledWith(2);
  });

  it('supports vertical variant', () => {
    render(<NumberSelect initialValue={3} variant="vertical" />);
    expect(screen.getByText('3')).toBeInTheDocument();
  });
});
