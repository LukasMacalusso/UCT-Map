import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MapEditorPanel } from './MapEditorPanel';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';

describe('MapEditorPanel', () => {
  it('renders default buttons and handles tool toggle', () => {
    const onSelectTool = vi.fn();
    render(<MapEditorPanel activeTool="none" onSelectTool={onSelectTool} />);

    const createBtn = screen.getByTitle('Añadir marcador');
    fireEvent.click(createBtn);
    expect(onSelectTool).toHaveBeenCalledWith('create');

    const moveBtn = screen.getByTitle('Mover marcador en el mapa');
    fireEvent.click(moveBtn);
    expect(onSelectTool).toHaveBeenCalledWith('move');
  });

  it('untoggles currently active tool to none', () => {
    const onSelectTool = vi.fn();
    render(<MapEditorPanel activeTool="create" onSelectTool={onSelectTool} />);

    const cancelCreateBtn = screen.getByTitle('Cancelar creación');
    fireEvent.click(cancelCreateBtn);
    expect(onSelectTool).toHaveBeenCalledWith('none');
  });

  it('renders building selection details and deselects', () => {
    const onDeselect = vi.fn();
    const onSelectTool = vi.fn();
    const building: BuildingLocationDto = {
      id: 'b1',
      name: 'Edificio Central',
      location: { latitude: -38.7, longitude: -72.6 },
      isSuspended: false,
      campusId: 'c1',
      metadata: { campusId: 'c1', floorsCount: 3, schedule: '08:00 - 18:00' },
    };

    render(
      <MapEditorPanel
        selectedBuilding={building}
        onDeselect={onDeselect}
        onSelectTool={onSelectTool}
      />,
    );

    expect(screen.getByText('Edificio Central')).toBeInTheDocument();
    expect(screen.getByText('3 pisos')).toBeInTheDocument();

    const editBtn = screen.getByTitle('Editar detalles del elemento');
    fireEvent.click(editBtn);
    expect(onSelectTool).toHaveBeenCalledWith('inspect');

    const deleteBtn = screen.getByTitle('Eliminar marcador');
    fireEvent.click(deleteBtn);
    expect(onSelectTool).toHaveBeenCalledWith('delete');

    const deselectBtn = screen.getByTitle('Deseleccionar marcador');
    fireEvent.click(deselectBtn);
    expect(onDeselect).toHaveBeenCalled();
  });

  it('renders structure selection details', () => {
    const onDeselectBuilding = vi.fn();
    const structure: StructureDto = {
      id: 's1',
      name: 'Casino UCT',
      latitude: -38.7,
      longitude: -72.6,
      categoryId: 'cat1',
      buildingId: 'b1',
      campusId: 'c1',
    };

    render(
      <MapEditorPanel
        selectedStructure={structure}
        onDeselectBuilding={onDeselectBuilding}
      />,
    );

    expect(screen.getByText('Casino UCT')).toBeInTheDocument();
    expect(screen.getByText('Estructura')).toBeInTheDocument();

    const deselectBtn = screen.getByTitle('Deseleccionar marcador');
    fireEvent.click(deselectBtn);
    expect(onDeselectBuilding).toHaveBeenCalled();
  });
});
