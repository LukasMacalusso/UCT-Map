import { useState, useCallback, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { MapEditorPanel, type EditorMapTool } from '../../modules/admin/MapEditorPanel';
import { EditorMapCanvas } from './EditorMapCanvas';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { TimedActionCard } from '../../components/ui/TimedActionCard';
import { useUiState } from '../../states/uiState';
import {
  useCampuses,
  useCreateBuilding,
  useUpdateBuilding,
  useDeleteBuilding,
  useCreateStructure,
  useUpdateStructure,
  useDeleteStructure,
  useCategories,
} from '../../hooks/useCampus';
import type { BuildingLocationDto } from '../../dtos/campus/BuildingLocationDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';

import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';

export const EditorMapSubView = () => {
  const navigate = useNavigate();
  const notifyEditor = useUiState((state) => state.notifyEditor);

  // Active Tool & Selected Marker
  const [activeTool, setActiveTool] = useState<EditorMapTool>('none');
  const [selectedBuilding, setSelectedBuilding] = useState<BuildingLocationDto | null>(null);
  const [selectedStructure, setSelectedStructure] = useState<StructureDto | null>(null);
  const [activeCampusId, setActiveCampusId] = useState('');

  // Creation modal state
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [pendingCoords, setPendingCoords] = useState<[number, number] | null>(null);
  const [newEntityType, setNewEntityType] = useState<'building' | 'structure'>('building');
  const [newEntityName, setNewEntityName] = useState('');
  const [newFloorsCount, setNewFloorsCount] = useState(1);
  const [newCategoryId, setNewCategoryId] = useState('');
  const [createCampusId, setCreateCampusId] = useState('');

  // Deletion modal state
  const [deletingBuilding, setDeletingBuilding] = useState<BuildingLocationDto | null>(null);
  const [deletingStructure, setDeletingStructure] = useState<StructureDto | null>(null);

  // Queries & Mutations
  const { data: campuses } = useCampuses();
  const { data: categories } = useCategories();

  const createBuilding = useCreateBuilding();
  const updateBuilding = useUpdateBuilding();
  const deleteBuilding = useDeleteBuilding();
  const createStructure = useCreateStructure();
  const updateStructure = useUpdateStructure();
  const deleteStructure = useDeleteStructure();

  const effectiveCampusId = activeCampusId || campuses?.[0]?.id || '';

  // Cancel tool or selection on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setActiveTool('none');
        setIsCreateOpen(false);
        setDeletingBuilding(null);
        setDeletingStructure(null);
        setSelectedBuilding(null);
        setSelectedStructure(null);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Map Ground Click (triggered in 'create' mode or deselects)
  const handleMapClick = useCallback(
    (coords: [number, number]) => {
      if (activeTool === 'create') {
        const [lng, lat] = coords;
        setPendingCoords([lng, lat]);
        setNewEntityName('');
        setNewEntityType('building');
        setNewFloorsCount(1);
        setNewCategoryId(categories?.[0]?.id || '');
        setCreateCampusId(effectiveCampusId);
        setIsCreateOpen(true);
      } else {
        // Deselect if clicking on empty map space
        setSelectedBuilding(null);
        setSelectedStructure(null);
      }
    },
    [activeTool, categories, effectiveCampusId],
  );

  const handleCampusChange = useCallback((campusId: string) => {
    setActiveCampusId(campusId);
    setSelectedBuilding(null);
    setSelectedStructure(null);
    setActiveTool('none');
  }, []);

  // Marker Click
  const handleBuildingClick = useCallback(
    (building: BuildingLocationDto) => {
      setSelectedBuilding(building);
      setSelectedStructure(null);

      if (activeTool === 'inspect') {
        navigate(`/edition/buildings?id=${building.id}&type=building`);
      } else if (activeTool === 'delete') {
        setDeletingBuilding(building);
      }
    },
    [activeTool, navigate],
  );

  const handleStructureClick = useCallback(
    (structure: StructureDto) => {
      setSelectedStructure(structure);
      setSelectedBuilding(null);

      if (activeTool === 'inspect') {
        navigate(`/edition/buildings?id=${structure.id}&type=structure`);
      } else if (activeTool === 'delete') {
        setDeletingStructure(structure);
      }
    },
    [activeTool, navigate],
  );

  // Handle Tool selection from Panel
  const handleSelectTool = useCallback(
    (tool: EditorMapTool) => {
      if (tool === 'inspect') {
        if (selectedBuilding) {
          navigate(`/edition/buildings?id=${selectedBuilding.id}&type=building`);
          return;
        }
        if (selectedStructure) {
          navigate(`/edition/buildings?id=${selectedStructure.id}&type=structure`);
          return;
        }
      }
      if (tool === 'delete') {
        if (selectedBuilding) {
          setDeletingBuilding(selectedBuilding);
          return;
        }
        if (selectedStructure) {
          setDeletingStructure(selectedStructure);
          return;
        }
      }
      setActiveTool(tool);
    },
    [navigate, selectedBuilding, selectedStructure],
  );

  // Marker Drag End (triggered in 'move' mode)
  const handleMarkerDragEnd = useCallback(
    (building: BuildingLocationDto, coords: [number, number]) => {
      const [lng, lat] = coords;
      setSelectedBuilding(building);
      setSelectedStructure(null);
      updateBuilding.mutate(
        {
          id: building.id,
          payload: {
            campusId: building.metadata.campusId,
            name: building.name,
            floorsCount: building.metadata.floorsCount || 1,
            latitude: lat,
            longitude: lng,
            services: building.metadata.services?.join(', ') || undefined,
            openTime: building.metadata.schedule ? undefined : undefined,
          },
        },
        {
          onSuccess: () => {
            notifyEditor(`Ubicación de "${building.name}" actualizada con éxito.`);
          },
        },
      );
    },
    [updateBuilding, notifyEditor],
  );

  const handleStructureMarkerDragEnd = useCallback(
    (structure: StructureDto, coords: [number, number]) => {
      const [lng, lat] = coords;
      setSelectedStructure(structure);
      setSelectedBuilding(null);
      updateStructure.mutate(
        {
          id: structure.id,
          payload: {
            campusId: structure.campusId,
            categoryId: structure.categoryId,
            name: structure.name,
            latitude: lat,
            longitude: lng,
          },
        },
        {
          onSuccess: () => {
            notifyEditor(`Ubicación de "${structure.name}" actualizada con éxito.`);
          },
        },
      );
    },
    [updateStructure, notifyEditor],
  );

  // Submit creation
  const handleSaveCreate = () => {
    if (!pendingCoords || !newEntityName.trim() || !createCampusId) return;
    const [lng, lat] = pendingCoords;

    if (newEntityType === 'building') {
      createBuilding.mutate(
        {
          campusId: createCampusId,
          name: newEntityName.trim(),
          floorsCount: Math.max(1, newFloorsCount),
          latitude: lat,
          longitude: lng,
        },
        {
          onSuccess: (created) => {
            setIsCreateOpen(false);
            setActiveTool('none');
            notifyEditor(`Edificio "${created.name}" creado con éxito.`);
          },
        },
      );
    } else {
      createStructure.mutate(
        {
          campusId: createCampusId,
          categoryId: newCategoryId || null,
          name: newEntityName.trim(),
          latitude: lat,
          longitude: lng,
        },
        {
          onSuccess: (created) => {
            setIsCreateOpen(false);
            setActiveTool('none');
            notifyEditor(`Estructura "${created.name}" creada con éxito.`);
          },
        },
      );
    }
  };

  // Confirm delete
  const handleConfirmDelete = () => {
    if (deletingBuilding) {
      deleteBuilding.mutate(deletingBuilding.id, {
        onSuccess: () => {
          notifyEditor(`Edificio "${deletingBuilding.name}" eliminado.`);
          if (selectedBuilding?.id === deletingBuilding.id) {
            setSelectedBuilding(null);
          }
          setDeletingBuilding(null);
          setActiveTool('none');
        },
      });
    } else if (deletingStructure) {
      deleteStructure.mutate(deletingStructure.id, {
        onSuccess: () => {
          notifyEditor(`Estructura "${deletingStructure.name}" eliminada.`);
          if (selectedStructure?.id === deletingStructure.id) {
            setSelectedStructure(null);
          }
          setDeletingStructure(null);
          setActiveTool('none');
        },
      });
    }
  };

  // Determine cursor mode
  const cursorMode =
    activeTool === 'create'
      ? 'crosshair'
      : activeTool === 'move'
      ? 'grab'
      : activeTool === 'inspect' || activeTool === 'delete'
      ? 'pointer'
      : 'default';

  // Centered top action banner (vertically aligned with Campus select)
  const topBanner =
    activeTool !== 'none' ? (
      <div className="h-14 flex items-center pointer-events-auto">
        <div className="bg-page-dark/95 text-white shadow-xl px-5 py-2.5 rounded-2xl flex items-center gap-4 border border-white/10 backdrop-blur-md">
          <span className="text-xs font-bold tracking-wide">
            {activeTool === 'create' &&
              'Haz clic en el mapa para ubicar un nuevo marcador'}
            {activeTool === 'inspect' &&
              'Haz clic en un marcador para editar sus detalles'}
            {activeTool === 'move' &&
              'Arrastra cualquier marcador a su nueva posición'}
            {activeTool === 'delete' &&
              'Haz clic en el marcador que deseas borrar'}
          </span>

          <Button
            size="sm"
            variant="outline"
            color="white"
            className="!w-auto !px-3 !py-1 text-xs border-white/20 text-white hover:bg-white/10"
            onClick={() => setActiveTool('none')}
          >
            Cancelar
          </Button>
        </div>
      </div>
    ) : null;

  return (
    <div className="w-full h-full relative overflow-hidden">
      <EditorMapCanvas
        topMessage={topBanner}
        selectedBuildingId={selectedBuilding?.id ?? null}
        onBuildingClick={handleBuildingClick}
        selectedStructureId={selectedStructure?.id ?? null}
        onStructureClick={handleStructureClick}
        onMapClick={handleMapClick}
        markersDraggable={activeTool === 'move'}
        onMarkerDragEnd={handleMarkerDragEnd}
        onStructureMarkerDragEnd={handleStructureMarkerDragEnd}
        cursorMode={cursorMode}
        onCampusChange={handleCampusChange}
      >
        {/* Bottom Left Toolbar with Dynamic Actions & Info Card */}
        <div className="absolute bottom-6 left-6 z-20">
          <MapEditorPanel
            activeTool={activeTool}
            onSelectTool={handleSelectTool}
            selectedBuilding={selectedBuilding}
            selectedStructure={selectedStructure}
            onDeselectBuilding={() => {
              setSelectedBuilding(null);
              setSelectedStructure(null);
              setActiveTool('none');
            }}
          />
        </div>
      </EditorMapCanvas>

      {/* Modal: Create Building or Structure */}
      <ModalOverlay isOpen={isCreateOpen} onClose={() => setIsCreateOpen(false)}>
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Nuevo Marcador en el Mapa
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            {/* Coordinates Badge */}
            {pendingCoords && (
              <div className="text-[11px] text-gray-500 bg-gray-50 p-2.5 rounded-xl border border-gray-100 flex items-center justify-between">
                <span className="font-semibold">Coordenadas seleccionadas:</span>
                <span className="font-mono text-page-blue font-bold">
                  {pendingCoords[1].toFixed(5)}, {pendingCoords[0].toFixed(5)}
                </span>
              </div>
            )}

            {/* Entity Type Toggle */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">
                Tipo de elemento
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setNewEntityType('building')}
                  className={`py-2 px-3 rounded-xl font-bold text-xs flex items-center justify-center gap-2 border transition-all cursor-pointer ${
                    newEntityType === 'building'
                      ? 'bg-page-blue text-white border-page-blue shadow-sm'
                      : 'bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100'
                  }`}
                >
                  <BuildingIcon className="w-4 h-4" />
                  Edificio
                </button>

                <button
                  type="button"
                  onClick={() => setNewEntityType('structure')}
                  className={`py-2 px-3 rounded-xl font-bold text-xs flex items-center justify-center gap-2 border transition-all cursor-pointer ${
                    newEntityType === 'structure'
                      ? 'bg-page-blue text-white border-page-blue shadow-sm'
                      : 'bg-gray-50 text-gray-700 border-gray-200 hover:bg-gray-100'
                  }`}
                >
                  <CubeIcon className="w-4 h-4" />
                  Estructura
                </button>
              </div>
            </div>

            {/* Campus Select */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">
                Campus asignado
              </label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={createCampusId}
                onChange={(e) => setCreateCampusId(e.target.value)}
              >
                {(campuses ?? []).map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>

            {/* Name Input */}
            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">
                {newEntityType === 'building' ? 'Nombre del edificio' : 'Nombre de la estructura'}
              </label>
              <Input
                placeholder={
                  newEntityType === 'building'
                    ? 'Ej: Pabellón C, Edificio San Francisco'
                    : 'Ej: Cancha de Fútbol, Quincho, Estacionamiento Central'
                }
                value={newEntityName}
                onChange={(e) => setNewEntityName(e.target.value)}
              />
            </div>

            {/* Building Specific: Floors Count */}
            {newEntityType === 'building' ? (
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-gray-700 uppercase">
                  Cantidad de pisos
                </label>
                <Input
                  type="number"
                  min={1}
                  max={50}
                  value={newFloorsCount}
                  onChange={(e) => setNewFloorsCount(Math.max(1, parseInt(e.target.value, 10) || 1))}
                />
              </div>
            ) : (
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-bold text-gray-700 uppercase">
                  Categoría / Filtro
                </label>
                <select
                  className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                  value={newCategoryId}
                  onChange={(e) => setNewCategoryId(e.target.value)}
                >
                  <option value="">Sin categoría</option>
                  {(categories ?? []).map((cat) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {(createBuilding.isError || createStructure.error) && (
              <span className="text-xs text-page-red">
                {createBuilding.error?.message || createStructure.error?.message}
              </span>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <Button
              color="blue"
              className="flex-1 !w-auto"
              onClick={handleSaveCreate}
              disabled={
                !newEntityName.trim() ||
                !createCampusId ||
                createBuilding.isPending ||
                createStructure.isPending
              }
            >
              {createBuilding.isPending || createStructure.isPending
                ? 'Creando...'
                : 'Crear marcador'}
            </Button>
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsCreateOpen(false)}
            >
              Cancelar
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Delete Building Confirmation */}
      <ModalOverlay isOpen={!!deletingBuilding} onClose={() => setDeletingBuilding(null)}>
        <TimedActionCard
          title="Eliminar edificio"
          description={`¿Estás seguro de que deseas eliminar "${deletingBuilding?.name}"? Esta acción no se puede deshacer.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setDeletingBuilding(null),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: handleConfirmDelete,
            },
          ]}
        />
      </ModalOverlay>

      {/* Modal: Delete Structure Confirmation */}
      <ModalOverlay isOpen={!!deletingStructure} onClose={() => setDeletingStructure(null)}>
        <TimedActionCard
          title="Eliminar estructura"
          description={`¿Estás seguro de que deseas eliminar la estructura "${deletingStructure?.name}"? Esta acción no se puede deshacer.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setDeletingStructure(null),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: handleConfirmDelete,
            },
          ]}
        />
      </ModalOverlay>
    </div>
  );
};
