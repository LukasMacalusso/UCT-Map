import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Panel } from '../../components/layout/Panel';
import { SearchInput } from '../../components/ui/SearchInput';
import { Select } from '../../components/ui/Select';
import { Button } from '../../components/ui/Button';
import { SquareButton } from '../../components/ui/SquareButton';
import { Input } from '../../components/ui/Input';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { TimedActionCard } from '../../components/ui/TimedActionCard';
import {
  useBuildingLocations,
  useCampuses,
  useStructures,
  useCategories,
  useBuildingRooms,
  useCreateRoom,
  useUpdateRoom,
  useDeleteRoom,
  useUpdateBuilding,
  useDeleteBuilding,
  useUpdateStructure,
  useDeleteStructure,
} from '../../hooks/useCampus';
import type { RoomDto } from '../../dtos/campus/RoomDto';
import { useUiState } from '../../states/uiState';

import SearchIcon from '../../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';
import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';
import TrashIcon from '../../assets/svg/icons/icon_trash.svg?react';
import PlusIcon from '../../assets/svg/icons/icon_plus.svg?react';
import DoorIcon from '../../assets/svg/icons/icon_door.svg?react';
import FloorsIcon from '../../assets/svg/icons/icon_floors.svg?react';
import ScheduleIcon from '../../assets/svg/icons/icon_schedule.svg?react';

type EntityFilter = 'all' | 'buildings' | 'structures';

export const EditorBuildingsSubView = () => {
  const [searchParams] = useSearchParams();
  const paramId = searchParams.get('id');
  const paramType = (searchParams.get('type') as 'building' | 'structure') || 'building';

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCampus, setSelectedCampus] = useState('');
  const [entityFilter, setEntityFilter] = useState<EntityFilter>('all');
  const [selectedId, setSelectedId] = useState<string | null>(paramId);
  const [selectedType, setSelectedType] = useState<'building' | 'structure'>(paramType);
  const [selectedFloor, setSelectedFloor] = useState<number | 'all'>('all');

  // Room modal state
  const [isAddRoomOpen, setIsAddRoomOpen] = useState(false);
  const [newRoomName, setNewRoomName] = useState('');
  const [newRoomFloor, setNewRoomFloor] = useState<number>(1);
  const [newRoomCategoryId, setNewRoomCategoryId] = useState('');

  const [editingRoom, setEditingRoom] = useState<RoomDto | null>(null);
  const [editRoomName, setEditRoomName] = useState('');
  const [editRoomFloor, setEditRoomFloor] = useState<number>(1);
  const [editRoomCategoryId, setEditRoomCategoryId] = useState('');

  const [deletingRoom, setDeletingRoom] = useState<RoomDto | null>(null);

  // Building edit modal state
  const [isEditBuildingOpen, setIsEditBuildingOpen] = useState(false);
  const [editBuildingName, setEditBuildingName] = useState('');
  const [editBuildingFloorsCount, setEditBuildingFloorsCount] = useState(1);
  const [editBuildingSchedule, setEditBuildingSchedule] = useState('');
  const [editBuildingServices, setEditBuildingServices] = useState('');

  // Structure edit modal state
  const [isEditStructureOpen, setIsEditStructureOpen] = useState(false);
  const [editStructureName, setEditStructureName] = useState('');
  const [editStructureCategoryId, setEditStructureCategoryId] = useState('');

  // Delete modal states (visual)
  const [isDeleteBuildingModalOpen, setIsDeleteBuildingModalOpen] = useState(false);
  const [isDeleteStructureModalOpen, setIsDeleteStructureModalOpen] = useState(false);
  const [isDeleteFloorModalOpen, setIsDeleteFloorModalOpen] = useState(false);

  // Queries
  const { data: campuses } = useCampuses();
  const { data: buildings, isLoading: areBuildingsLoading } = useBuildingLocations(
    selectedCampus || undefined,
  );
  const { data: structures, isLoading: areStructuresLoading } = useStructures(
    selectedCampus || undefined,
  );
  const { data: categories } = useCategories();

  // Mutations
  const createRoom = useCreateRoom();
  const updateRoom = useUpdateRoom();
  const deleteRoom = useDeleteRoom(selectedId ?? undefined);
  const updateBuilding = useUpdateBuilding();
  const deleteBuilding = useDeleteBuilding();
  const updateStructure = useUpdateStructure();
  const deleteStructure = useDeleteStructure();

  const notifyEditor = useUiState((state) => state.notifyEditor);

  // Active Building / Structure
  const selectedBuilding = useMemo(
    () => (selectedType === 'building' ? (buildings ?? []).find((b) => b.id === selectedId) : null),
    [buildings, selectedId, selectedType],
  );

  const selectedStructure = useMemo(
    () => (selectedType === 'structure' ? (structures ?? []).find((s) => s.id === selectedId) : null),
    [structures, selectedId, selectedType],
  );

  const { data: rooms, isLoading: areRoomsLoading } = useBuildingRooms(
    selectedType === 'building' && selectedId ? selectedId : undefined,
  );

  const campusOptions = [
    { value: '', label: 'Todos los campus' },
    ...(campuses ?? []).map((campus) => ({ value: campus.id, label: campus.name })),
  ];

  const typeOptions = [
    { value: 'all', label: 'Todo' },
    { value: 'buildings', label: 'Edificio' },
    { value: 'structures', label: 'Estructura' },
  ];

  // Category map for quick lookup
  const categoryMap = useMemo(() => {
    const map = new Map<string, string>();
    (categories ?? []).forEach((c) => map.set(c.id, c.name));
    return map;
  }, [categories]);

  // Campus map for quick lookup
  const campusMap = useMemo(() => {
    const map = new Map<string, string>();
    (campuses ?? []).forEach((c) => map.set(c.id, c.name));
    return map;
  }, [campuses]);

  // Unified items list
  const filteredItems = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const items: Array<{
      id: string;
      name: string;
      type: 'building' | 'structure';
      campusId: string;
      floorsCount?: number;
      categoryId?: string | null;
    }> = [];

    if (entityFilter === 'all' || entityFilter === 'buildings') {
      (buildings ?? []).forEach((b) => {
        if (!q || b.name.toLowerCase().includes(q)) {
          items.push({
            id: b.id,
            name: b.name,
            type: 'building',
            campusId: b.metadata.campusId,
            floorsCount: b.metadata.floorsCount,
          });
        }
      });
    }

    if (entityFilter === 'all' || entityFilter === 'structures') {
      (structures ?? []).forEach((s) => {
        if (!q || s.name.toLowerCase().includes(q)) {
          items.push({
            id: s.id,
            name: s.name,
            type: 'structure',
            campusId: s.campusId,
            categoryId: s.categoryId,
          });
        }
      });
    }

    return items;
  }, [buildings, structures, searchQuery, entityFilter]);

  // Handlers
  const handleSelectItem = (id: string, type: 'building' | 'structure') => {
    setSelectedId(id);
    setSelectedType(type);
    setSelectedFloor('all');
  };

  const handleOpenAddRoom = () => {
    setNewRoomName('');
    setNewRoomFloor(1);
    setNewRoomCategoryId(categories?.[0]?.id || '');
    setIsAddRoomOpen(true);
  };

  const handleCreateRoom = () => {
    if (!selectedId || !newRoomName.trim() || !newRoomCategoryId) return;

    const rName = newRoomName.trim();
    createRoom.mutate(
      {
        buildingId: selectedId,
        categoryId: newRoomCategoryId,
        name: rName,
        floor: newRoomFloor,
      },
      {
        onSuccess: () => {
          setIsAddRoomOpen(false);
          setNewRoomName('');
          notifyEditor(`Sala "${rName}" creada con éxito.`);
        },
      },
    );
  };

  const handleStartEditRoom = (room: RoomDto) => {
    setEditingRoom(room);
    setEditRoomName(room.name);
    setEditRoomFloor(room.floor);
    setEditRoomCategoryId(room.categoryId);
  };

  const handleSaveEditRoom = () => {
    if (!editingRoom || !selectedId || !editRoomName.trim() || !editRoomCategoryId) return;

    const rName = editRoomName.trim();
    updateRoom.mutate(
      {
        id: editingRoom.id,
        payload: {
          buildingId: selectedId,
          categoryId: editRoomCategoryId,
          name: rName,
          floor: editRoomFloor,
        },
      },
      {
        onSuccess: () => {
          setEditingRoom(null);
          notifyEditor(`Sala "${rName}" actualizada con éxito.`);
        },
      },
    );
  };

  const handleDeleteRoom = () => {
    if (!deletingRoom) return;

    const rName = deletingRoom.name;
    deleteRoom.mutate(deletingRoom.id, {
      onSuccess: () => {
        setDeletingRoom(null);
        notifyEditor(`Sala "${rName}" eliminada.`);
      },
    });
  };

  const handleOpenEditBuilding = () => {
    if (!selectedBuilding) return;
    setEditBuildingName(selectedBuilding.name);
    setEditBuildingFloorsCount(selectedBuilding.metadata.floorsCount || 1);
    setEditBuildingSchedule(selectedBuilding.metadata.schedule || '');
    setEditBuildingServices(selectedBuilding.metadata.services?.join(', ') || '');
    setIsEditBuildingOpen(true);
  };

  const handleSaveEditBuilding = () => {
    if (!selectedBuilding) return;

    const bName = editBuildingName.trim();
    updateBuilding.mutate(
      {
        id: selectedBuilding.id,
        payload: {
          campusId: selectedBuilding.metadata.campusId,
          name: bName,
          floorsCount: Math.max(1, editBuildingFloorsCount),
          latitude: selectedBuilding.location.latitude,
          longitude: selectedBuilding.location.longitude,
          services: editBuildingServices.trim() || undefined,
        },
      },
      {
        onSuccess: () => {
          setIsEditBuildingOpen(false);
          notifyEditor(`Edificio "${bName}" actualizado con éxito.`);
        },
      },
    );
  };

  const handleOpenEditStructure = () => {
    if (!selectedStructure) return;
    setEditStructureName(selectedStructure.name);
    setEditStructureCategoryId(selectedStructure.categoryId ?? '');
    setIsEditStructureOpen(true);
  };

  const handleSaveEditStructure = () => {
    if (!selectedStructure || !editStructureName.trim()) return;
    const sName = editStructureName.trim();
    updateStructure.mutate(
      {
        id: selectedStructure.id,
        payload: {
          campusId: selectedStructure.campusId,
          categoryId: editStructureCategoryId || null,
          name: sName,
          latitude: selectedStructure.latitude,
          longitude: selectedStructure.longitude,
        },
      },
      {
        onSuccess: () => {
          setIsEditStructureOpen(false);
          notifyEditor(`Estructura "${sName}" actualizada con éxito.`);
        },
      },
    );
  };

  // Rooms filtered by floor
  const displayedRooms = useMemo(() => {
    if (!rooms) return [];
    if (selectedFloor === 'all') return rooms;
    return rooms.filter((r) => r.floor === selectedFloor);
  }, [rooms, selectedFloor]);

  const floorsCount = selectedBuilding?.metadata.floorsCount || 1;
  const floorsList = useMemo(() => {
    return Array.from({ length: floorsCount }, (_, i) => i + 1);
  }, [floorsCount]);

  const campusName = useMemo(() => {
    const cId = selectedBuilding?.metadata.campusId || selectedStructure?.campusId;
    return campuses?.find((c) => c.id === cId)?.name ?? '—';
  }, [campuses, selectedBuilding, selectedStructure]);

  return (
    <div className="w-full h-full bg-transparent p-6 flex flex-col gap-5 overflow-hidden">
      {/* Top Filter & Search Bar */}
      <div className="flex flex-wrap items-end justify-end gap-3 flex-shrink-0">
        <div className="w-72">
          <SearchInput
            label="Búsqueda"
            labelColor="text-white"
            placeholder="Buscar por nombre..."
            value={searchQuery}
            onChange={setSearchQuery}
            icon={<SearchIcon className="w-5 h-5 text-gray-500" />}
            showSuggestions={false}
          />
        </div>

        <div className="w-52">
          <Select
            label="Tipo"
            options={typeOptions}
            value={entityFilter}
            onChange={(val) => setEntityFilter(val as EntityFilter)}
            icon={<CubeIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>

        <div className="w-64">
          <Select
            label="Campus"
            options={campusOptions}
            value={selectedCampus}
            onChange={setSelectedCampus}
            icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>
      </div>

      {/* Main Grid: Left List & Right Detail/Editor */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 flex-1 min-h-0 w-full items-stretch">
        {/* Left Column: List (4 cols) */}
        <div className="lg:col-span-4 h-full min-h-0 flex flex-col">
          <Panel
            withUctBorder={false}
            outerClassName="!w-full !h-full min-h-0 shadow-lg"
            innerClassName="p-6 flex flex-col gap-3 h-full min-h-0"
          >
            <div className="flex items-center justify-between pb-2 border-b border-gray-100">
              <h2 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
                Lista ({filteredItems.length})
              </h2>
            </div>

            <div className="flex flex-1 min-h-0 flex-col gap-2.5 overflow-y-auto pr-1">
              {(areBuildingsLoading || areStructuresLoading) && (
                <span className="text-sm text-gray-500 py-6 text-center">Cargando elementos...</span>
              )}

              {filteredItems.length === 0 && !areBuildingsLoading && !areStructuresLoading && (
                <span className="text-sm text-gray-500 py-6 text-center">
                  Sin elementos para mostrar.
                </span>
              )}

              {filteredItems.map((item) => {
                const isSelected = item.id === selectedId;
                const isBuilding = item.type === 'building';

                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => handleSelectItem(item.id, item.type)}
                    className={`flex w-full items-center gap-3.5 rounded-2xl border p-3.5 text-left transition-all cursor-pointer ${
                      isSelected
                        ? 'border-page-blue bg-blue-50/60 shadow-sm'
                        : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50/60'
                    }`}
                  >
                    <div
                      className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-xs ${
                        isBuilding ? 'bg-page-blue text-white' : 'bg-page-yellow text-white'
                      }`}
                    >
                      {isBuilding ? (
                        <BuildingIcon className="w-5 h-5 text-white" />
                      ) : (
                        <CubeIcon className="w-5 h-5 text-white" />
                      )}
                    </div>

                    <div className="flex flex-col min-w-0 flex-1">
                      <span className="truncate text-base font-bold text-gray-800">
                        {item.name}
                      </span>
                      <div className="flex items-center gap-1.5 text-xs font-semibold text-gray-500 truncate mt-0.5">
                        <span className="truncate">{campusMap.get(item.campusId) ?? 'Campus'}</span>
                        <span className="text-gray-300">•</span>
                        <span className="shrink-0">
                          {isBuilding
                            ? `${item.floorsCount || 1} ${(item.floorsCount || 1) === 1 ? 'piso' : 'pisos'}`
                            : (categoryMap.get(item.categoryId ?? '') || 'Sin categoría')}
                        </span>
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </Panel>
        </div>

        {/* Right Column: Detail & Editor (8 cols) */}
        <div className="lg:col-span-8 h-full min-h-0 flex flex-col">
          <Panel
            withUctBorder={false}
            outerClassName="!w-full !h-full min-h-0 shadow-lg"
            innerClassName="p-6 md:p-8 flex flex-col gap-4 h-full min-h-0"
          >
            {!selectedBuilding && !selectedStructure && (
              <div className="flex flex-1 items-center justify-center text-sm text-gray-400">
                Selecciona un edificio o estructura de la lista para gestionar sus datos y salas.
              </div>
            )}

            {/* Structure Detail */}
            {selectedStructure && (
              <div className="flex flex-1 min-h-0 flex-col gap-5 overflow-y-auto pr-1">
                <div className="flex items-start justify-between pb-3 border-b border-gray-100">
                  <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                      <CubeIcon className="w-4 h-4 text-amber-600 shrink-0" />
                      <span className="text-xs text-gray-400">•</span>
                      <span className="text-xs font-semibold text-gray-500">{campusName}</span>
                    </div>
                    <h2 className="text-xl font-extrabold text-gray-800 tracking-tight">
                      {selectedStructure.name}
                    </h2>
                  </div>

                  <div className="flex items-center gap-2.5">
                    <Button
                      size="md"
                      variant="outline"
                      color="red"
                      className="!w-auto flex items-center gap-2 text-sm font-bold"
                      onClick={() => setIsDeleteStructureModalOpen(true)}
                    >
                      <TrashIcon className="w-4 h-4" />
                      Eliminar estructura
                    </Button>

                    <Button
                      size="md"
                      variant="outline"
                      color="yellow"
                      className="!w-auto flex items-center gap-2 text-sm font-bold text-page-dark"
                      onClick={handleOpenEditStructure}
                    >
                      <PencilIcon className="w-4 h-4" />
                      Editar estructura
                    </Button>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 rounded-2xl bg-gray-50 p-4 border border-gray-200">
                  <div className="flex flex-col gap-1">
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">Campus</span>
                    <span className="text-base font-bold text-gray-800">{campusName}</span>
                  </div>
                  <div className="flex flex-col gap-1">
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">Categoría</span>
                    <span className="text-base font-bold text-gray-800">
                      {categoryMap.get(selectedStructure.categoryId ?? '') ?? 'Sin categoría'}
                    </span>
                  </div>
                  <div className="flex flex-col gap-1">
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">Latitud</span>
                    <span className="text-sm font-semibold text-gray-700">
                      {Number(selectedStructure.latitude).toFixed(2)}
                    </span>
                  </div>
                  <div className="flex flex-col gap-1">
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">Longitud</span>
                    <span className="text-sm font-semibold text-gray-700">
                      {Number(selectedStructure.longitude).toFixed(2)}
                    </span>
                  </div>
                </div>

                <div className="rounded-2xl border border-amber-200 bg-amber-50/70 p-4 text-xs font-medium text-amber-900 flex items-start gap-2.5">
                  <CubeIcon className="w-5 h-5 text-amber-600 flex-shrink-0 mt-0.5" />
                  <span>
                    Las estructuras no contienen salas.
                  </span>
                </div>
              </div>
            )}

            {/* Building Detail & Room Editor */}
            {selectedBuilding && (
              <div className="flex flex-1 min-h-0 flex-col gap-4 overflow-y-auto pr-1">
                {/* Header with building info & edit button */}
                <div className="flex items-start justify-between pb-3 border-b border-gray-100">
                  <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                      <BuildingIcon className="w-4 h-4 text-page-blue shrink-0" />
                      <span className="text-xs text-gray-400">•</span>
                      <span className="text-xs font-semibold text-gray-500">{campusName}</span>
                    </div>
                    <h2 className="text-xl font-extrabold text-gray-800 tracking-tight">
                      {selectedBuilding.name}
                    </h2>
                  </div>

                  <div className="flex items-center gap-2.5">
                    <Button
                      size="md"
                      variant="outline"
                      color="red"
                      className="!w-auto flex items-center gap-2 text-sm font-bold"
                      onClick={() => setIsDeleteBuildingModalOpen(true)}
                    >
                      <TrashIcon className="w-4 h-4" />
                      Eliminar edificio
                    </Button>

                    <Button
                      size="md"
                      variant="outline"
                      color="blue"
                      className="!w-auto flex items-center gap-2 text-sm font-bold"
                      onClick={handleOpenEditBuilding}
                    >
                      <PencilIcon className="w-4 h-4" />
                      Editar edificio
                    </Button>
                  </div>
                </div>

                {/* Building Quick Metadata */}
                <div className="grid grid-cols-3 gap-4 rounded-2xl bg-gray-50 p-4 border border-gray-200">
                  {/* Total pisos */}
                  <div className="flex items-center gap-3.5">
                    <div className="flex items-center justify-center w-11 h-11 rounded-xl bg-page-blue text-white shadow-xs flex-shrink-0">
                      <FloorsIcon className="w-5 h-5 text-white" />
                    </div>
                    <div className="flex flex-col min-w-0">
                      <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">
                        Total pisos
                      </span>
                      <span className="text-lg font-extrabold text-gray-800">
                        {selectedBuilding.metadata.floorsCount}
                      </span>
                    </div>
                  </div>

                  {/* Total salas */}
                  <div className="flex items-center gap-3.5">
                    <div className="flex items-center justify-center w-11 h-11 rounded-xl bg-page-blue text-white shadow-xs flex-shrink-0">
                      <DoorIcon className="w-5 h-5 text-white" />
                    </div>
                    <div className="flex flex-col min-w-0">
                      <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">
                        Total salas
                      </span>
                      <span className="text-lg font-extrabold text-gray-800">
                        {rooms?.length ?? 0}
                      </span>
                    </div>
                  </div>

                  {/* Horario */}
                  <div className="flex items-center gap-3.5">
                    <div className="flex items-center justify-center w-11 h-11 rounded-xl bg-page-blue text-white shadow-xs flex-shrink-0">
                      <ScheduleIcon className="w-5 h-5 text-white" />
                    </div>
                    <div className="flex flex-col min-w-0">
                      <span className="text-xs font-bold text-gray-400 uppercase tracking-wide">
                        Horario
                      </span>
                      <span className="text-base font-bold text-gray-700 truncate">
                        {selectedBuilding.metadata.schedule || 'Sin horario'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Room Management Section */}
                <div className="flex flex-col gap-3.5 flex-1 min-h-0 pt-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <DoorIcon className="w-5 h-5 text-page-blue" />
                      <h3 className="text-base font-bold text-gray-800 uppercase tracking-tight">
                        Salas por piso
                      </h3>
                    </div>

                    <div className="flex items-center gap-2.5">
                      <Button
                        size="md"
                        variant="outline"
                        color="red"
                        className="!w-auto flex items-center gap-2 text-sm font-bold"
                        onClick={() => setIsDeleteFloorModalOpen(true)}
                      >
                        <TrashIcon className="w-4 h-4" />
                        Eliminar piso
                      </Button>

                      <Button
                        size="md"
                        variant="outline"
                        color="blue"
                        className="!w-auto flex items-center gap-2 text-sm font-bold"
                        onClick={handleOpenAddRoom}
                      >
                        <PlusIcon className="w-4 h-4" />
                        Añadir sala
                      </Button>
                    </div>
                  </div>

                  {/* Floor Selector Bar */}
                  <div className="flex items-center gap-2 overflow-x-auto pb-1.5 pt-0.5">
                    <FloorsIcon className="w-5 h-5 text-gray-400 mr-1 flex-shrink-0" />
                    <button
                      type="button"
                      onClick={() => setSelectedFloor('all')}
                      className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                        selectedFloor === 'all'
                          ? 'bg-page-blue text-white shadow-sm'
                          : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                      }`}
                    >
                      Todos los pisos ({rooms?.length ?? 0})
                    </button>

                    {floorsList.map((f) => {
                      const countInFloor = (rooms ?? []).filter((r) => r.floor === f).length;
                      return (
                        <button
                          key={f}
                          type="button"
                          onClick={() => setSelectedFloor(f)}
                          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap ${
                            selectedFloor === f
                              ? 'bg-page-blue text-white shadow-sm'
                              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                          }`}
                        >
                          Piso {f} ({countInFloor})
                        </button>
                      );
                    })}
                  </div>

                  {/* Room List */}
                  <div className="flex flex-1 min-h-0 flex-col gap-2 overflow-y-auto pr-1">
                    {areRoomsLoading && (
                      <span className="text-sm text-gray-400 py-6 text-center">Cargando salas...</span>
                    )}

                    {!areRoomsLoading && displayedRooms.length === 0 && (
                      <div className="flex flex-col items-center justify-center py-8 text-center border-2 border-dashed border-gray-200 rounded-2xl">
                        <DoorIcon className="w-8 h-8 text-gray-300 mb-1" />
                        <span className="text-sm font-semibold text-gray-500">
                          {selectedFloor === 'all'
                            ? 'No hay salas registradas en este edificio.'
                            : `No hay salas registradas en el Piso ${selectedFloor}.`}
                        </span>
                      </div>
                    )}

                    {displayedRooms.map((room) => {
                      return (
                        <div
                          key={room.id}
                          className="group flex items-center justify-between gap-3 rounded-2xl border border-gray-200 bg-white p-3.5 hover:border-gray-300 transition-colors"
                        >
                          <div className="flex items-center gap-3.5 min-w-0">
                            <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-page-blue text-white shadow-xs flex-shrink-0">
                              <DoorIcon className="w-5 h-5 text-white" />
                            </div>

                            <div className="flex flex-col min-w-0">
                              <span className="text-base md:text-lg font-bold text-gray-800 truncate">
                                {room.name}
                              </span>
                              <div className="flex items-center gap-2 mt-1">
                                <span className="text-xs font-bold text-page-blue bg-blue-50 border border-blue-100 px-2 py-0.5 rounded-md leading-none">
                                  Piso {room.floor}
                                </span>
                                <span className="text-sm font-semibold text-gray-500">
                                  {categoryMap.get(room.categoryId) ?? 'Sin categoría'}
                                </span>
                              </div>
                            </div>
                          </div>

                          {/* Room actions: SquareButton de tamaño consistente */}
                          <div className="flex items-center gap-2 opacity-80 group-hover:opacity-100 transition-opacity flex-shrink-0">
                            <SquareButton
                              type="button"
                              title="Editar sala"
                              className="!w-10 !h-10 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-blue hover:bg-blue-50/70 transition-colors [&>span]:!w-5 [&>span]:!h-5"
                              onClick={() => handleStartEditRoom(room)}
                            >
                              <PencilIcon className="w-5 h-5 pointer-events-none text-page-blue" />
                            </SquareButton>

                            <SquareButton
                              type="button"
                              title="Eliminar sala"
                              className="!w-10 !h-10 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-red hover:bg-red-50/70 active:!bg-page-red transition-colors [&>span]:!w-5 [&>span]:!h-5"
                              onClick={() => setDeletingRoom(room)}
                            >
                              <TrashIcon className="w-5 h-5 pointer-events-none text-page-red" />
                            </SquareButton>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </Panel>
        </div>
      </div>

      {/* Modal: Add Room */}
      <ModalOverlay isOpen={isAddRoomOpen} onClose={() => setIsAddRoomOpen(false)}>
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Añadir nueva sala
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre de la sala"
              placeholder="Ej: Sala 101, Lab de Computación"
              value={newRoomName}
              onChange={(e) => setNewRoomName(e.target.value)}
            />

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Piso</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={newRoomFloor}
                onChange={(e) => setNewRoomFloor(Number(e.target.value))}
              >
                {floorsList.map((f) => (
                  <option key={f} value={f}>
                    Piso {f}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Categoría</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={newRoomCategoryId}
                onChange={(e) => setNewRoomCategoryId(e.target.value)}
              >
                {(categories ?? []).map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>

            {createRoom.isError && (
              <span className="text-xs text-page-red">{createRoom.error.message}</span>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <Button
              color="blue"
              className="flex-1 !w-auto"
              onClick={handleCreateRoom}
              disabled={!newRoomName.trim() || !newRoomCategoryId || createRoom.isPending}
            >
              {createRoom.isPending ? 'Creando...' : 'Crear sala'}
            </Button>
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsAddRoomOpen(false)}
            >
              Cancelar
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Edit Room */}
      <ModalOverlay isOpen={!!editingRoom} onClose={() => setEditingRoom(null)}>
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Editar sala
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre de la sala"
              placeholder="Ej: Sala 101"
              value={editRoomName}
              onChange={(e) => setEditRoomName(e.target.value)}
            />

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Piso</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={editRoomFloor}
                onChange={(e) => setEditRoomFloor(Number(e.target.value))}
              >
                {floorsList.map((f) => (
                  <option key={f} value={f}>
                    Piso {f}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Categoría</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={editRoomCategoryId}
                onChange={(e) => setEditRoomCategoryId(e.target.value)}
              >
                {(categories ?? []).map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>

            {updateRoom.isError && (
              <span className="text-xs text-page-red">{updateRoom.error.message}</span>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <Button
              color="blue"
              className="flex-1 !w-auto"
              onClick={handleSaveEditRoom}
              disabled={!editRoomName.trim() || !editRoomCategoryId || updateRoom.isPending}
            >
              {updateRoom.isPending ? 'Guardando...' : 'Guardar cambios'}
            </Button>
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setEditingRoom(null)}
            >
              Cancelar
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Delete Room Confirmation */}
      <ModalOverlay isOpen={!!deletingRoom} onClose={() => setDeletingRoom(null)}>
        <TimedActionCard
          title="Eliminar sala"
          description={`¿Estás seguro de que deseas eliminar la sala "${deletingRoom?.name}"? Esta acción no se puede deshacer.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setDeletingRoom(null),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: handleDeleteRoom,
            },
          ]}
        />
      </ModalOverlay>

      {/* Modal: Edit Building Properties */}
      <ModalOverlay isOpen={isEditBuildingOpen} onClose={() => setIsEditBuildingOpen(false)}>
        <div className="w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Editar edificio
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre del edificio"
              placeholder="Nombre"
              value={editBuildingName}
              onChange={(e) => setEditBuildingName(e.target.value)}
            />

            <Input
              label="Cantidad de pisos"
              type="number"
              min={1}
              max={50}
              value={editBuildingFloorsCount}
              onChange={(e) => setEditBuildingFloorsCount(Math.max(1, Number(e.target.value)))}
            />

            <Input
              label="Horario (opcional)"
              placeholder="Ej: 08:00 - 20:00"
              value={editBuildingSchedule}
              onChange={(e) => setEditBuildingSchedule(e.target.value)}
            />

            <Input
              label="Servicios (opcional, separados por coma)"
              placeholder="Ej: Wifi, Baños, Biblioteca"
              value={editBuildingServices}
              onChange={(e) => setEditBuildingServices(e.target.value)}
            />

            {updateBuilding.isError && (
              <span className="text-xs text-page-red">{updateBuilding.error.message}</span>
            )}
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-gray-100">
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsEditBuildingOpen(false)}
            >
              Cancelar
            </Button>
            <Button
              color="blue"
              className="!w-auto px-5"
              onClick={handleSaveEditBuilding}
              disabled={!editBuildingName.trim() || updateBuilding.isPending}
            >
              {updateBuilding.isPending ? 'Guardando...' : 'Guardar edificio'}
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Edit Structure Properties */}
      <ModalOverlay isOpen={isEditStructureOpen} onClose={() => setIsEditStructureOpen(false)}>
        <div className="w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Editar estructura
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre de la estructura"
              placeholder="Nombre"
              value={editStructureName}
              onChange={(e) => setEditStructureName(e.target.value)}
            />

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Categoría</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={editStructureCategoryId}
                onChange={(e) => setEditStructureCategoryId(e.target.value)}
              >
                <option value="">Sin categoría</option>
                {(categories ?? []).map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-gray-100">
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsEditStructureOpen(false)}
            >
              Cancelar
            </Button>
            <Button
              color="blue"
              className="!w-auto px-5"
              onClick={handleSaveEditStructure}
              disabled={!editStructureName.trim() || updateStructure.isPending}
            >
              {updateStructure.isPending ? 'Guardando...' : 'Guardar estructura'}
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Delete Building Confirmation */}
      <ModalOverlay
        isOpen={isDeleteBuildingModalOpen}
        onClose={() => setIsDeleteBuildingModalOpen(false)}
      >
        <TimedActionCard
          title="Eliminar Edificio"
          description={`¿Estás seguro de que deseas eliminar el edificio "${selectedBuilding?.name}"? Esta acción no se puede deshacer.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setIsDeleteBuildingModalOpen(false),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: () => {
                if (!selectedBuilding) return;
                const bName = selectedBuilding.name || 'Edificio';
                deleteBuilding.mutate(selectedBuilding.id, {
                  onSuccess: () => {
                    setIsDeleteBuildingModalOpen(false);
                    setSelectedId(null);
                    notifyEditor(`Edificio "${bName}" eliminado.`);
                  },
                });
              },
            },
          ]}
        />
      </ModalOverlay>

      {/* Modal: Delete Structure Confirmation */}
      <ModalOverlay
        isOpen={isDeleteStructureModalOpen}
        onClose={() => setIsDeleteStructureModalOpen(false)}
      >
        <TimedActionCard
          title="Eliminar Estructura"
          description={`¿Estás seguro de que deseas eliminar la estructura "${selectedStructure?.name}"? Esta acción no se puede deshacer.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setIsDeleteStructureModalOpen(false),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: () => {
                if (!selectedStructure) return;
                const sName = selectedStructure.name || 'Estructura';
                deleteStructure.mutate(selectedStructure.id, {
                  onSuccess: () => {
                    setIsDeleteStructureModalOpen(false);
                    setSelectedId(null);
                    notifyEditor(`Estructura "${sName}" eliminada.`);
                  },
                });
              },
            },
          ]}
        />
      </ModalOverlay>

      {/* Modal: Delete Floor Confirmation (Visual) */}
      <ModalOverlay
        isOpen={isDeleteFloorModalOpen}
        onClose={() => setIsDeleteFloorModalOpen(false)}
      >
        <TimedActionCard
          title="Eliminar Piso"
          description={`¿Estás seguro de que deseas eliminar el piso del edificio "${selectedBuilding?.name}"?`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setIsDeleteFloorModalOpen(false),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: () => {
                setIsDeleteFloorModalOpen(false);
                notifyEditor('Piso eliminado con éxito.');
              },
            },
          ]}
        />
      </ModalOverlay>
    </div>
  );
};
