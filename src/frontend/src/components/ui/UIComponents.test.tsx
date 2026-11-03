import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { CategoryIcon } from './CategoryIcon';
import { CheckboxItem } from './CheckboxItem';
import { FileUpload } from './FileUpload';
import { GeometricBackground } from './GeometricBackground';
import { MapMarker } from './MapMarker';
import { NavButton } from './NavButton';
import { SquareButton } from './SquareButton';
import { SectionButton } from './SectionButton';
import { UserActionInfo } from './UserActionInfo';
import { SearchInput } from './SearchInput';
import { TimedActionCard } from './TimedActionCard';

describe('UI Components', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    if (!window.URL.createObjectURL) {
      window.URL.createObjectURL = vi.fn(() => 'blob:mock-url');
    } else {
      vi.spyOn(window.URL, 'createObjectURL').mockReturnValue('blob:mock-url');
    }
  });
  it('renders CategoryIcon variants', () => {
    const { rerender } = render(<CategoryIcon icon="book" data-testid="cat-icon" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="computer" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="building" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="door" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="users" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="study" />);
    expect(document.querySelector('svg')).toBeInTheDocument();

    rerender(<CategoryIcon icon="unknown-icon" />);
    expect(document.querySelector('svg')).toBeInTheDocument();
  });

  it('renders CheckboxItem and toggles input', () => {
    const onChange = vi.fn();
    render(<CheckboxItem label="Opción 1" desc="Descripción 1" onChange={onChange} />);

    expect(screen.getByText('Opción 1')).toBeInTheDocument();
    expect(screen.getByText('Descripción 1')).toBeInTheDocument();

    const checkbox = screen.getByRole('checkbox');
    fireEvent.click(checkbox);
    expect(onChange).toHaveBeenCalled();
  });

  it('renders FileUpload and handles drag-and-drop, file selection, controls, and removal', () => {
    const onFilesChange = vi.fn();
    const { container } = render(<FileUpload maxFiles={3} onFilesChange={onFilesChange} />);

    expect(screen.getByText(/ARRASTRA MÁXIMO 3 IMÁGENES/i)).toBeInTheDocument();

    const dropZone = container.firstChild as HTMLElement;
    fireEvent.dragOver(dropZone);
    expect(screen.getByText(/SUELTA LAS IMÁGENES AQUÍ/i)).toBeInTheDocument();

    fireEvent.dragLeave(dropZone);
    expect(screen.getByText(/ARRASTRA MÁXIMO 3 IMÁGENES/i)).toBeInTheDocument();

    // Drop files
    const file1 = new File(['dummy content 1'], 'test1.png', { type: 'image/png' });
    const file2 = new File(['dummy content 2'], 'test2.png', { type: 'image/png' });
    fireEvent.drop(dropZone, {
      dataTransfer: {
        files: [file1, file2],
      },
    });

    expect(onFilesChange).toHaveBeenCalledWith([file1, file2]);
    expect(screen.getByAltText('Preview 1')).toBeInTheDocument();

    // Controls: next and prev
    const nextBtn = screen.getByRole('button', { name: /siguiente/i });
    fireEvent.click(nextBtn);

    const prevBtn = screen.getByRole('button', { name: /anterior/i });
    fireEvent.click(prevBtn);

    // Slide indicator click
    const slide2Btn = screen.getByRole('button', { name: /ir a la diapositiva 2/i });
    fireEvent.click(slide2Btn);

    // Hover mouse enter/leave for pause/resume
    fireEvent.mouseEnter(dropZone);
    fireEvent.mouseLeave(dropZone);

    // Add more button
    const addBtn = screen.getByText(/\+ Añadir/i);
    expect(addBtn).toBeInTheDocument();

    // Remove current image
    const closeBtn = screen.getByRole('button', { name: /cerrar/i });
    fireEvent.click(closeBtn);
    expect(onFilesChange).toHaveBeenCalled();
  });

  it('renders SearchInput, filters options, selects an option and closes on outside click', () => {
    const onChange = vi.fn();
    const onSelectOption = vi.fn();
    const options = [
      { label: 'Campus Norte', value: 'cn' },
      { label: 'Campus Sur', value: 'cs' },
    ];

    const { rerender } = render(
      <SearchInput
        value=""
        onChange={onChange}
        onSelectOption={onSelectOption}
        options={options}
        placeholder="Buscar campus"
      />,
    );

    const input = screen.getByPlaceholderText('Buscar campus');
    fireEvent.focus(input);
    fireEvent.change(input, { target: { value: 'Norte' } });
    expect(onChange).toHaveBeenCalledWith('Norte');

    rerender(
      <SearchInput
        value="Norte"
        onChange={onChange}
        onSelectOption={onSelectOption}
        options={options}
        placeholder="Buscar campus"
      />,
    );

    const optionBtn = screen.getByText('Campus Norte');
    fireEvent.click(optionBtn);
    expect(onSelectOption).toHaveBeenCalledWith(options[0]);

    // Outside click
    fireEvent.mouseDown(document.body);
  });

  it('renders TimedActionCard and enables buttons after duration', () => {
    vi.useFakeTimers();
    const onConfirm = vi.fn();
    const onCancel = vi.fn();

    render(
      <TimedActionCard
        title="Acción Peligrosa"
        description="Espera el contador"
        initialDurationMs={1000}
        options={[
          { label: 'Confirmar', onClick: onConfirm },
          { label: 'Cancelar', onClick: onCancel },
        ]}
      />,
    );

    expect(screen.getByText('Acción Peligrosa')).toBeInTheDocument();
    const confirmBtn = screen.getByText('Confirmar');
    expect(confirmBtn).toBeDisabled();

    act(() => {
      vi.advanceTimersByTime(1100);
    });

    expect(confirmBtn).not.toBeDisabled();
    fireEvent.click(confirmBtn);
    expect(onConfirm).toHaveBeenCalled();

    vi.useRealTimers();
  });

  it('renders GeometricBackground', () => {
    render(<GeometricBackground />);
    expect(document.querySelector('svg')).toBeInTheDocument();
  });

  it('renders MapMarker', () => {
    render(<MapMarker color="blue" isActive={true} icon={<span>Marker</span>} />);
    expect(screen.getByText('Marker')).toBeInTheDocument();
  });

  it('renders NavButton inside Router', () => {
    render(
      <MemoryRouter initialEntries={['/']}>
        <NavButton to="/test" label="Mi Enlace" size="md" width="auto" />
      </MemoryRouter>,
    );
    expect(screen.getByText('Mi Enlace')).toBeInTheDocument();
  });

  it('renders SquareButton', () => {
    const onClick = vi.fn();
    render(<SquareButton onClick={onClick}><span>Btn</span></SquareButton>);
    fireEvent.click(screen.getByText('Btn'));
    expect(onClick).toHaveBeenCalled();
  });

  it('renders SectionButton', () => {
    render(
      <MemoryRouter>
        <SectionButton to="/sec1" label="Sección 1" isExpanded={true} />
      </MemoryRouter>,
    );
    expect(screen.getByText('Sección 1')).toBeInTheDocument();
  });

  it('renders UserActionInfo', () => {
    render(<UserActionInfo title="Juan Pérez" subtitle="Estudiante" />);
    expect(screen.getByText('Juan Pérez')).toBeInTheDocument();
    expect(screen.getByText('Estudiante')).toBeInTheDocument();
  });
});
