import { useMemo, useState } from 'react';
import { Button } from '../../components/ui/Button';
import { Panel } from '../../components/layout/Panel';
import { SquareButton } from '../../components/ui/SquareButton';
import { Input } from '../../components/ui/Input';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { TimedActionCard } from '../../components/ui/TimedActionCard';
import {
  useCampuses,
  useCreateCampus,
  useUpdateCampus,
  useDeleteCampus,
  useBuildingLocations,
  useStructures,
} from '../../hooks/useCampus';
import {
  getSharedMapCamera,
  applySharedMapCamera,
  type CampusCamera,
} from '../../modules/map/CampusMapCanvas';
import { EditorMapCanvas } from './EditorMapCanvas';
import { CampusCameraInfo } from './CampusCameraInfo';
import type { CampusDto } from '../../dtos/campus/CampusDto';
import { textPageColors } from '../../constants/colors';
import { useUiState } from '../../states/uiState';

import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';
import CameraIcon from '../../assets/svg/icons/icon_camera.svg?react';

type PanelMode = 'list' | 'create' | 'edit';

export const EditorCampusSubView = () => {
  const [mode, setMode] = useState<PanelMode>('list');
  const [selectedCampusId, setSelectedCampusId] = useState<string | null>(null);

  // Create form state
  const [createName, setCreateName] = useState('');
  const [createAddress, setCreateAddress] = useState('');
  const [createCamera, setCreateCamera] = useState<CampusCamera | null>(null);

  // Edit form state
  const [editName, setEditName] = useState('');
  const [editAddress, setEditAddress] = useState('');
  const [editCamera, setEditCamera] = useState<CampusCamera | null>(null);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);

  const notifyEditor = useUiState((state) => state.notifyEditor);

  // Queries & Mutations
  const { data: campuses, isLoading: areCampusesLoading } = useCampuses();
  const { data: allBuildings, isLoading: areBuildingsLoading } = useBuildingLocations();
  const { data: allStructures, isLoading: areStructuresLoading } = useStructures();

  const createCampus = useCreateCampus();
  const updateCampus = useUpdateCampus();
  const deleteCampus = useDeleteCampus();

  const selectedCampus = campuses?.find((item) => item.id === selectedCampusId) ?? null;

  // Counts of buildings and structures per campus
  const buildingCountByCampus = useMemo(() => {
    const map: Record<string, number> = {};
    (allBuildings ?? []).forEach((b) => {
      const cId = b.metadata?.campusId;
      if (cId) {
        map[cId] = (map[cId] || 0) + 1;
      }
    });
    return map;
  }, [allBuildings]);

  const structureCountByCampus = useMemo(() => {
    const map: Record<string, number> = {};
    (allStructures ?? []).forEach((s) => {
      const cId = s.campusId;
      if (cId) {
        map[cId] = (map[cId] || 0) + 1;
      }
    });
    return map;
  }, [allStructures]);

  const selectedBuildingCount = selectedCampusId ? (buildingCountByCampus[selectedCampusId] ?? 0) : 0;
  const selectedStructureCount = selectedCampusId ? (structureCountByCampus[selectedCampusId] ?? 0) : 0;
  const hasAssociatedEntities = selectedBuildingCount > 0 || selectedStructureCount > 0;

  // Handlers for list
  const handleSelectCampus = (campus: CampusDto) => {
    setSelectedCampusId(campus.id);
    applySharedMapCamera(campus, true);
  };

  const handleStartEdit = (campus: CampusDto) => {
    setSelectedCampusId(campus.id);
    setEditName(campus.name);
    setEditAddress(campus.address || '');
    setEditCamera({
      latitude: campus.latitude,
      longitude: campus.longitude,
      zoom: campus.zoom,
      pitch: campus.pitch,
      bearing: campus.bearing,
    });
    setMode('edit');
    applySharedMapCamera(campus, true);
  };

  const handleStartCreate = () => {
    setCreateName('');
    setCreateAddress('');
    setCreateCamera(getSharedMapCamera());
    setMode('create');
  };

  const handleBackToList = () => {
    setMode('list');
  };

  // Handlers for create
  const handleCaptureCreateCamera = () => {
    const cam = getSharedMapCamera();
    if (cam) setCreateCamera(cam);
  };

  const canCreate =
    createName.trim().length > 0 &&
    createAddress.trim().length > 0 &&
    createCamera !== null &&
    !createCampus.isPending;

  const handleCreate = () => {
    if (!createCamera || !canCreate) return;

    createCampus.mutate(
      {
        name: createName.trim(),
        address: createAddress.trim(),
        latitude: createCamera.latitude,
        longitude: createCamera.longitude,
        zoom: createCamera.zoom,
        pitch: createCamera.pitch,
        bearing: createCamera.bearing,
      },
      {
        onSuccess: (newCampus) => {
          setSelectedCampusId(newCampus.id);
          setMode('list');
          notifyEditor(`Campus "${newCampus.name}" creado con éxito.`);
        },
      },
    );
  };

  // Handlers for edit
  const handleCaptureEditCamera = () => {
    const cam = getSharedMapCamera();
    if (cam) setEditCamera(cam);
  };

  const canUpdate =
    editName.trim().length > 0 &&
    editAddress.trim().length > 0 &&
    editCamera !== null &&
    !updateCampus.isPending;

  const handleUpdate = () => {
    if (!selectedCampusId || !editCamera || !canUpdate) return;

    updateCampus.mutate(
      {
        id: selectedCampusId,
        payload: {
          name: editName.trim(),
          address: editAddress.trim(),
          latitude: editCamera.latitude,
          longitude: editCamera.longitude,
          zoom: editCamera.zoom,
          pitch: editCamera.pitch,
          bearing: editCamera.bearing,
        },
      },
      {
        onSuccess: () => {
          notifyEditor(`Campus "${editName.trim()}" actualizado con éxito.`);
        },
      },
    );
  };

  const handleDelete = () => {
    if (!selectedCampusId) return;

    deleteCampus.mutate(selectedCampusId, {
      onSuccess: () => {
        setIsDeleteModalOpen(false);
        setSelectedCampusId(null);
        setMode('list');
        notifyEditor('Campus eliminado con éxito.');
      },
    });
  };

  return (
    <EditorMapCanvas
      campusId={selectedCampusId ?? undefined}
      showCampusSelector={false}
      showControls={false}
    >
      <div className="absolute top-6 right-6 bottom-6 z-40 flex w-[28.25rem] flex-col">
        <Panel
          withUctBorder={false}
          size="sm"
          outerClassName="shadow-2xl !h-full"
          innerClassName="p-6 flex flex-col gap-4 min-h-0"
        >
          {/* ==================================================== */}
          {/* MODE: LIST                                           */}
          {/* ==================================================== */}
          {mode === 'list' && (
            <>
              <div className="flex items-center justify-between pb-1 border-b border-gray-100">
                <div className="flex flex-col">
                  <h2 className="text-xl font-extrabold text-gray-800 uppercase tracking-tight">
                    Campus
                  </h2>
                  <span className="text-sm text-gray-500 font-medium">
                    {campuses
                      ? `${campuses.length} ${campuses.length === 1 ? 'campus registrado' : 'campus registrados'}`
                      : 'Cargando campus...'}
                  </span>
                </div>
              </div>

              <div className="flex flex-1 min-h-0 flex-col gap-2.5 overflow-y-auto pr-1">
                {areCampusesLoading && (
                  <div className="flex items-center justify-center py-10 text-base text-gray-500">
                    Cargando lista de campus...
                  </div>
                )}

                {!areCampusesLoading && (campuses ?? []).length === 0 && (
                  <div className="flex flex-col items-center justify-center py-10 text-center text-sm text-gray-500">
                    No hay campus registrados actualmente.
                  </div>
                )}

                {(campuses ?? []).map((campus) => {
                  const isSelected = selectedCampusId === campus.id;
                  const bCount = buildingCountByCampus[campus.id] ?? 0;
                  const sCount = structureCountByCampus[campus.id] ?? 0;

                  return (
                    <div
                      key={campus.id}
                      onClick={() => handleSelectCampus(campus)}
                      className={`flex items-start justify-between gap-3 rounded-2xl border p-3.5 transition-all cursor-pointer ${
                        isSelected
                          ? 'border-page-blue bg-blue-50/60 shadow-sm'
                          : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50/60'
                      }`}
                    >
                      <div className="flex flex-col min-w-0 flex-1">
                        <span className="truncate text-base md:text-lg font-bold text-gray-800">
                          {campus.name}
                        </span>
                        <span className="truncate text-sm md:text-base text-gray-400 mt-1">
                          {campus.address || 'Sin dirección registrada'}
                        </span>

                        <div className="flex flex-wrap items-center gap-1.5 mt-2">
                          <span
                            className="inline-flex items-center gap-1 rounded-lg bg-page-blue px-2 py-0.5 text-xs font-bold text-white shadow-xs"
                            title={`${bCount} edificios asociados`}
                          >
                            <BuildingIcon className="w-3.5 h-3.5 text-white" />
                            <span>
                              {bCount} {bCount === 1 ? 'edificio' : 'edificios'}
                            </span>
                          </span>

                          <span
                            className="inline-flex items-center gap-1 rounded-lg bg-page-yellow px-2 py-0.5 text-xs font-bold text-white shadow-xs"
                            title={`${sCount} estructuras asociadas`}
                          >
                            <CubeIcon className="w-3.5 h-3.5 text-white" />
                            <span>
                              {sCount} {sCount === 1 ? 'estructura' : 'estructuras'}
                            </span>
                          </span>
                        </div>
                      </div>

                      <SquareButton
                        type="button"
                        title="Editar campus"
                        className="!w-10 !h-10 shrink-0 !shadow-none border border-gray-200 hover:border-page-blue mt-0.5"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleStartEdit(campus);
                        }}
                      >
                        <PencilIcon className="w-5 h-5 pointer-events-none text-page-blue" />
                      </SquareButton>
                    </div>
                  );
                })}
              </div>

              <Button
                type="button"
                color="blue"
                className="!w-full shrink-0"
                onClick={handleStartCreate}
              >
                Crear nuevo campus
              </Button>
            </>
          )}

          {/* ==================================================== */}
          {/* MODE: CREATE                                         */}
          {/* ==================================================== */}
          {mode === 'create' && (
            <>
              <div className="flex items-center gap-3 pb-2 border-b border-gray-100">
                <button
                  type="button"
                  onClick={handleBackToList}
                  className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors cursor-pointer"
                  title="Volver a la lista"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <div className="flex flex-col">
                  <h2 className="text-xl font-extrabold text-gray-800 uppercase tracking-tight">
                    Nuevo campus
                  </h2>
                  <span className="text-xs text-gray-500 font-medium">
                    Configura la información y cámara de presentación
                  </span>
                </div>
              </div>

              <div className="flex flex-1 min-h-0 flex-col gap-4 overflow-y-auto pr-1">
                <Input
                  label="Nombre"
                  labelColor="text-gray-700"
                  placeholder="Nombre del campus"
                  value={createName}
                  onChange={(event) => setCreateName(event.target.value)}
                />

                <Input
                  label="Dirección"
                  labelColor="text-gray-700"
                  placeholder="Dirección del campus"
                  value={createAddress}
                  onChange={(event) => setCreateAddress(event.target.value)}
                />

                <div className="flex flex-col gap-2 rounded-xl bg-gray-50 p-3 border border-gray-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded-lg bg-page-blue text-white flex items-center justify-center shrink-0 shadow-xs">
                        <CameraIcon className="w-3.5 h-3.5 text-white" />
                      </div>
                      <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wide">
                        Cámara de presentación
                      </h4>
                    </div>
                    <Button
                      type="button"
                      variant="ghost"
                      color="blue"
                      size="sm"
                      className="!w-auto !px-2.5 !py-1 text-xs flex items-center gap-1.5"
                      onClick={handleCaptureCreateCamera}
                    >
                      <CameraIcon className="w-3.5 h-3.5" />
                      Capturar actual
                    </Button>
                  </div>

                  {createCamera ? (
                    <CampusCameraInfo camera={createCamera} />
                  ) : (
                    <span className="text-xs text-gray-500 py-1.5 text-center">
                      Mueve el mapa a la vista deseada y pulsa "Capturar actual".
                    </span>
                  )}
                </div>

                {createCampus.isError && (
                  <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-xs text-page-red">
                    {createCampus.error.message}
                  </div>
                )}
              </div>

              <div className="flex gap-2 shrink-0 pt-2 border-t border-gray-100">
                <Button
                  type="button"
                  color="blue"
                  className="flex-1 !w-auto"
                  onClick={handleCreate}
                  disabled={!canCreate}
                >
                  {createCampus.isPending ? 'Creando...' : 'Crear campus'}
                </Button>

                <Button
                  type="button"
                  variant="outline"
                  color="gray"
                  className="!w-auto px-4"
                  onClick={handleBackToList}
                >
                  Cancelar
                </Button>
              </div>
            </>
          )}

          {/* ==================================================== */}
          {/* MODE: EDIT                                           */}
          {/* ==================================================== */}
          {mode === 'edit' && (
            <>
              <div className="flex items-center gap-3 pb-2 border-b border-gray-100">
                <button
                  type="button"
                  onClick={handleBackToList}
                  className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors cursor-pointer"
                  title="Volver a la lista"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 19l-7-7 7-7" />
                  </svg>
                </button>
                <div className="flex flex-col min-w-0">
                  <h2 className="text-xl font-extrabold text-gray-800 uppercase tracking-tight truncate">
                    Editar campus
                  </h2>
                  <span className="text-xs text-gray-500 font-medium truncate">
                    {selectedCampus?.name ?? 'Detalle del campus'}
                  </span>
                </div>
              </div>

              {!selectedCampus && (
                <div className="flex flex-1 items-center justify-center text-sm text-gray-500">
                  Campus no encontrado o cargando...
                </div>
              )}

              {selectedCampus && (
                <>
                  <div className="flex flex-1 min-h-0 flex-col gap-4 overflow-y-auto pr-1">
                    <Input
                      label="Nombre"
                      labelColor="text-gray-700"
                      placeholder="Nombre del campus"
                      value={editName}
                      onChange={(event) => setEditName(event.target.value)}
                    />

                    <Input
                      label="Dirección"
                      labelColor="text-gray-700"
                      placeholder="Dirección del campus"
                      value={editAddress}
                      onChange={(event) => setEditAddress(event.target.value)}
                    />

                    <div className="flex flex-col gap-2 rounded-xl bg-gray-50 p-3 border border-gray-200">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <div className="w-6 h-6 rounded-lg bg-page-blue text-white flex items-center justify-center shrink-0 shadow-xs">
                            <CameraIcon className="w-3.5 h-3.5 text-white" />
                          </div>
                          <h4 className="text-xs font-bold text-gray-700 uppercase tracking-wide">
                            Cámara de presentación
                          </h4>
                        </div>
                        <Button
                          type="button"
                          variant="ghost"
                          color="blue"
                          size="sm"
                          className="!w-auto !px-2.5 !py-1 text-xs flex items-center gap-1.5"
                          onClick={handleCaptureEditCamera}
                        >
                          <CameraIcon className="w-3.5 h-3.5" />
                          Capturar actual
                        </Button>
                      </div>

                      {editCamera ? (
                        <CampusCameraInfo camera={editCamera} />
                      ) : (
                        <span className="text-xs text-gray-500 py-1.5 text-center">Sin datos de cámara</span>
                      )}
                    </div>

                    <div className="flex flex-col gap-2 rounded-xl bg-gray-50 p-3 border border-gray-200">
                      <h4 className="text-xs font-bold text-gray-600 uppercase tracking-wide">
                        Elementos vinculados
                      </h4>
                      <div className="flex items-center justify-between text-sm text-gray-700">
                        <span className="flex items-center gap-1.5 font-medium">
                          <BuildingIcon className="w-3.5 h-3.5 text-page-blue" />
                          Edificios asociados:
                        </span>
                        <span className="font-bold">
                          {areBuildingsLoading
                            ? 'Cargando...'
                            : `${selectedBuildingCount} ${selectedBuildingCount === 1 ? 'edificio' : 'edificios'}`}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-sm text-gray-700">
                        <span className="flex items-center gap-1.5 font-medium">
                          <CubeIcon className={`w-3.5 h-3.5 ${textPageColors.yellow}`} />
                          Estructuras asociadas:
                        </span>
                        <span className="font-bold">
                          {areStructuresLoading
                            ? 'Cargando...'
                            : `${selectedStructureCount} ${selectedStructureCount === 1 ? 'estructura' : 'estructuras'}`}
                        </span>
                      </div>
                    </div>

                    {updateCampus.isError && (
                      <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-xs text-page-red">
                        {updateCampus.error.message}
                      </div>
                    )}

                    {deleteCampus.isError && (
                      <div className="rounded-xl bg-red-50 border border-red-200 p-2.5 text-xs text-page-red">
                        {deleteCampus.error.message}
                      </div>
                    )}
                  </div>

                  <div className="flex flex-col gap-2 shrink-0 pt-2 border-t border-gray-100">
                    <div className="flex gap-2">
                      <Button
                        type="button"
                        color="blue"
                        className="flex-1 !w-auto"
                        onClick={handleUpdate}
                        disabled={!canUpdate || updateCampus.isPending}
                      >
                        {updateCampus.isPending ? 'Guardando...' : 'Guardar cambios'}
                      </Button>

                      <Button
                        type="button"
                        variant="outline"
                        color="gray"
                        className="!w-auto px-4"
                        onClick={handleBackToList}
                      >
                        Volver
                      </Button>
                    </div>

                    <Button
                      type="button"
                      color="red"
                      variant="outline"
                      className="!w-full !py-2 text-sm cursor-pointer"
                      onClick={() => setIsDeleteModalOpen(true)}
                      disabled={areBuildingsLoading || areStructuresLoading || deleteCampus.isPending}
                    >
                      Eliminar este campus
                    </Button>
                  </div>
                </>
              )}
            </>
          )}
        </Panel>
      </div>

      <ModalOverlay isOpen={isDeleteModalOpen} onClose={() => setIsDeleteModalOpen(false)}>
        <TimedActionCard
          title="Eliminar campus"
          description={
            hasAssociatedEntities
              ? `Este campus tiene ${selectedBuildingCount} edificio${selectedBuildingCount === 1 ? '' : 's'} y ${selectedStructureCount} estructura${selectedStructureCount === 1 ? '' : 's'} asociada${selectedBuildingCount + selectedStructureCount === 1 ? '' : 's'}. Debes eliminarlos o reasignarlos antes de poder eliminar el campus.`
              : '¿Estás seguro de que deseas eliminar este campus? Esta acción no se puede deshacer.'
          }
          initialDurationMs={hasAssociatedEntities ? 0 : 2000}
          options={
            hasAssociatedEntities
              ? [
                  {
                    label: 'Entendido',
                    color: 'gray',
                    onClick: () => setIsDeleteModalOpen(false),
                  },
                ]
              : [
                  {
                    label: 'Cancelar',
                    color: 'gray',
                    onClick: () => setIsDeleteModalOpen(false),
                  },
                  {
                    label: 'Sí, eliminar',
                    color: 'red',
                    onClick: handleDelete,
                  },
                ]
          }
        />
      </ModalOverlay>
    </EditorMapCanvas>
  );
};
