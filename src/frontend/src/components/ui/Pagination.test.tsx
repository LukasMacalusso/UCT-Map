import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Pagination } from './Pagination';

describe('Pagination', () => {
  it('siempre muestra los botones de navegación (inicio, anterior, siguiente, fin)', () => {
    render(<Pagination currentPage={2} totalPages={3} onPageChange={() => {}} />);
    expect(screen.getByLabelText('Primera página')).toBeInTheDocument();
    expect(screen.getByLabelText('Página anterior')).toBeInTheDocument();
    expect(screen.getByLabelText('Página siguiente')).toBeInTheDocument();
    expect(screen.getByLabelText('Última página')).toBeInTheDocument();
  });

  it('oculta por completo el paginador cuando hay una sola página', () => {
    render(<Pagination currentPage={1} totalPages={1} onPageChange={() => {}} />);
    expect(screen.queryByLabelText('Paginación')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Primera página')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Página anterior')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Página siguiente')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Última página')).not.toBeInTheDocument();
    expect(screen.queryByLabelText('Ir a la página 1')).not.toBeInTheDocument();
  });

  it('muestra un botón por página cuando hay pocas', () => {
    render(<Pagination currentPage={2} totalPages={4} onPageChange={() => {}} />);
    expect(screen.getByLabelText('Ir a la página 1')).toBeInTheDocument();
    expect(screen.getByLabelText('Ir a la página 4')).toBeInTheDocument();
  });

  it('deshabilita "inicio"/"anterior" en la primera página y "siguiente"/"fin" en la última', () => {
    const { rerender } = render(
      <Pagination currentPage={1} totalPages={3} onPageChange={() => {}} />
    );
    expect(screen.getByLabelText('Primera página')).toBeDisabled();
    expect(screen.getByLabelText('Página anterior')).toBeDisabled();
    expect(screen.getByLabelText('Página siguiente')).not.toBeDisabled();
    expect(screen.getByLabelText('Última página')).not.toBeDisabled();

    rerender(<Pagination currentPage={3} totalPages={3} onPageChange={() => {}} />);
    expect(screen.getByLabelText('Primera página')).not.toBeDisabled();
    expect(screen.getByLabelText('Página anterior')).not.toBeDisabled();
    expect(screen.getByLabelText('Página siguiente')).toBeDisabled();
    expect(screen.getByLabelText('Última página')).toBeDisabled();
  });

  it('pinta amarillos los botones de navegación habilitados', () => {
    render(<Pagination currentPage={2} totalPages={3} onPageChange={() => {}} />);
    expect(screen.getByLabelText('Primera página')).toHaveClass('bg-page-yellow');
    expect(screen.getByLabelText('Página anterior')).toHaveClass('bg-page-yellow');
    expect(screen.getByLabelText('Página siguiente')).toHaveClass('bg-page-yellow');
    expect(screen.getByLabelText('Última página')).toHaveClass('bg-page-yellow');
  });

  it('no pinta amarillos los botones de navegación deshabilitados', () => {
    render(<Pagination currentPage={1} totalPages={3} onPageChange={() => {}} />);
    expect(screen.getByLabelText('Primera página')).not.toHaveClass('bg-page-yellow');
    expect(screen.getByLabelText('Página anterior')).not.toHaveClass('bg-page-yellow');
  });

  it('llama onPageChange con el número de página al hacer click', () => {
    const onChange = vi.fn();
    render(<Pagination currentPage={1} totalPages={3} onPageChange={onChange} />);
    fireEvent.click(screen.getByLabelText('Ir a la página 3'));
    expect(onChange).toHaveBeenCalledWith(3);
  });

  it('las flechas simples navegan a anterior/siguiente', () => {
    const onChange = vi.fn();
    render(<Pagination currentPage={2} totalPages={3} onPageChange={onChange} />);
    fireEvent.click(screen.getByLabelText('Página anterior'));
    expect(onChange).toHaveBeenCalledWith(1);
    fireEvent.click(screen.getByLabelText('Página siguiente'));
    expect(onChange).toHaveBeenCalledWith(3);
  });

  it('las flechas dobles navegan a la primera y a la última página', () => {
    const onChange = vi.fn();
    render(<Pagination currentPage={5} totalPages={10} onPageChange={onChange} />);
    fireEvent.click(screen.getByLabelText('Primera página'));
    expect(onChange).toHaveBeenCalledWith(1);
    fireEvent.click(screen.getByLabelText('Última página'));
    expect(onChange).toHaveBeenCalledWith(10);
  });

  it('no dispara onPageChange si el botón está deshabilitado', () => {
    const onChange = vi.fn();
    render(<Pagination currentPage={1} totalPages={3} onPageChange={onChange} />);
    fireEvent.click(screen.getByLabelText('Página anterior'));
    fireEvent.click(screen.getByLabelText('Primera página'));
    expect(onChange).not.toHaveBeenCalled();
  });

  it('ventanea los números con muchas páginas (muestra elipsis)', () => {
    render(<Pagination currentPage={10} totalPages={20} onPageChange={() => {}} />);
    expect(screen.getAllByText('···').length).toBeGreaterThan(0);
    expect(screen.getByLabelText('Ir a la página 1')).toBeInTheDocument();
    expect(screen.getByLabelText('Ir a la página 10')).toBeInTheDocument();
    expect(screen.getByLabelText('Ir a la página 20')).toBeInTheDocument();
  });
});
