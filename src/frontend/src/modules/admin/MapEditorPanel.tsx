import { SquareButton } from '../../components/ui/SquareButton';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import type { MapMarkerItem } from '../../interfaces/MapMarkerItem';

import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';
import TrashIcon from '../../assets/svg/icons/icon_trash.svg?react';
import MoveIcon from '../../assets/svg/icons/icon_move.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';
import CrossIcon from '../../assets/svg/icons/icon_cross.svg?react';

export type EditorMapTool = 'none' | 'create' | 'inspect' | 'move' | 'delete';

interface MapEditorPanelProps {
  activeTool?: EditorMapTool;
  onSelectTool?: (tool: EditorMapTool) => void;
  selectedMarker?: MapMarkerItem | null;
  selectedBuilding?: BuildingLocationDto | null;
  selectedStructure?: StructureDto | null;
  onDeselect?: () => void;
  onDeselectBuilding?: () => void;
}

export const MapEditorPanel = ({
  activeTool = 'none',
  onSelectTool,
  selectedMarker,
  selectedBuilding = null,
  selectedStructure = null,
  onDeselect,
  onDeselectBuilding,
}: MapEditorPanelProps) => {
  const handleToggle = (tool: EditorMapTool) => {
    if (!onSelectTool) return;
    onSelectTool(activeTool === tool ? 'none' : tool);
  };

  const handleClose = onDeselect ?? onDeselectBuilding;

  const currentMarker = selectedMarker ?? (
    selectedBuilding
      ? { type: 'building' as const, name: selectedBuilding.name, data: selectedBuilding }
      : selectedStructure
      ? { type: 'structure' as const, name: selectedStructure.name, data: selectedStructure }
      : null
  );

  const hasSelection = !!currentMarker;
  const isBuilding = currentMarker?.type === 'building';
  const buildingData = isBuilding ? (currentMarker.data as BuildingLocationDto) : null;

  return (
    <div className="flex flex-row items-center gap-2">
      {/* 1. Create Marker Button (always visible) */}
      <SquareButton
        title={activeTool === 'create' ? 'Cancelar creación' : 'Añadir marcador'}
        onClick={() => handleToggle('create')}
        className={`transition-all ${
          activeTool === 'create'
            ? '!bg-page-blue !text-white ring-2 ring-page-blue shadow-md scale-105'
            : ''
        }`}
      >
        <MapPinIcon className="w-7 h-7" />
      </SquareButton>

      {/* 2. Move Marker Button (always visible alongside Create) */}
      <SquareButton
        title={activeTool === 'move' ? 'Terminar de mover' : 'Mover marcador en el mapa'}
        onClick={() => handleToggle('move')}
        className={`transition-all ${
          activeTool === 'move'
            ? '!bg-page-green !text-white ring-2 ring-page-green shadow-md scale-105'
            : ''
        }`}
      >
        <MoveIcon className="w-7 h-7" />
      </SquareButton>

      {/* 3. Actions & Info Card for Selected Marker (only when a marker is selected) */}
      {hasSelection && (
        <>
          {/* Edit Marker Button */}
          <SquareButton
            title={activeTool === 'inspect' ? 'Cancelar edición' : 'Editar detalles del elemento'}
            onClick={() => handleToggle('inspect')}
            className={`transition-all ${
              activeTool === 'inspect'
                ? '!bg-page-yellow !text-page-dark ring-2 ring-page-yellow shadow-md scale-105'
                : ''
            }`}
          >
            <PencilIcon className="w-7 h-7" />
          </SquareButton>

          {/* Delete Marker Button */}
          <SquareButton
            title={activeTool === 'delete' ? 'Cancelar eliminación' : 'Eliminar marcador'}
            onClick={() => handleToggle('delete')}
            className={`transition-all ${
              activeTool === 'delete'
                ? '!bg-page-red !text-white ring-2 ring-page-red shadow-md scale-105'
                : 'hover:text-page-red'
            }`}
          >
            <TrashIcon className="w-7 h-7" />
          </SquareButton>

          {/* Basic Marker Info Panel */}
          <div className="h-14 px-4 bg-white rounded-2xl shadow-sm border border-gray-100 flex items-center justify-between gap-3.5 min-w-[260px] max-w-sm animate-in fade-in slide-in-from-left-2">
            <div className="flex items-center gap-2.5 min-w-0">
              <div
                className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                  isBuilding ? 'bg-blue-50 text-page-blue' : 'bg-amber-50 text-amber-600'
                }`}
              >
                {isBuilding ? (
                  <BuildingIcon className="w-5 h-5" />
                ) : (
                  <CubeIcon className="w-5 h-5" />
                )}
              </div>
              <div className="flex flex-col text-left min-w-0">
                <span
                  className="text-sm font-bold text-gray-800 truncate"
                  title={currentMarker.name}
                >
                  {currentMarker.name}
                </span>
                <span className="text-[11px] font-semibold text-gray-400 truncate">
                  {buildingData
                    ? `${buildingData.metadata?.floorsCount || 1} ${
                        (buildingData.metadata?.floorsCount || 1) === 1 ? 'piso' : 'pisos'
                      }`
                    : 'Estructura'}
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={handleClose}
              title="Deseleccionar marcador"
              className="p-1.5 rounded-lg text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-colors cursor-pointer shrink-0"
            >
              <CrossIcon className="w-4 h-4" />
            </button>
          </div>
        </>
      )}
    </div>
  );
};
