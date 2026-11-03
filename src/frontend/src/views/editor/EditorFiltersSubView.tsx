import { useMemo, useState } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Panel } from '../../components/layout/Panel';
import { Button } from '../../components/ui/Button';
import { SquareButton } from '../../components/ui/SquareButton';
import { Input } from '../../components/ui/Input';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { TimedActionCard } from '../../components/ui/TimedActionCard';
import { queryKeys } from '../../api/queryKeys';
import {
  useCategoryGroups,
  useCreateCategoryGroup,
  useUpdateCategoryGroup,
  useReorderCategoryGroups,
  useDeleteCategoryGroup,
  useCategories,
  useCreateCategory,
  useUpdateCategory,
  useReorderCategories,
  useDeleteCategory,
} from '../../hooks/useCampus';
import type { CategoryGroupDto } from '../../dtos/campus/CategoryGroupDto';
import type { CategoryDto } from '../../dtos/campus/CategoryDto';
import { CategoryIcon } from '../../components/ui/CategoryIcon';
import { useUiState } from '../../states/uiState';

import PlusIcon from '../../assets/svg/icons/icon_plus.svg?react';
import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';
import TrashIcon from '../../assets/svg/icons/icon_trash.svg?react';
import FilterIcon from '../../assets/svg/icons/icon_filter.svg?react';

const PRESET_ICONS = [
  { value: 'book', label: 'Libro / Académico' },
  { value: 'computer', label: 'Computador / Laboratorio' },
  { value: 'users', label: 'Personas / Espacio Común' },
  { value: 'building', label: 'Edificio / Infraestructura' },
  { value: 'door', label: 'Puerta / Sala' },
  { value: 'study', label: 'Estudio' },
  { value: 'coffee', label: 'Cafetería / Comida' },
  { value: 'wifi', label: 'Wifi' },
  { value: 'bath', label: 'Baños' },
];

const GripIcon = ({ className = 'w-5 h-5' }: { className?: string }) => (
  <svg
    className={className}
    viewBox="0 0 20 20"
    fill="currentColor"
    aria-hidden="true"
  >
    <circle cx="7" cy="5" r="1.5" />
    <circle cx="13" cy="5" r="1.5" />
    <circle cx="7" cy="10" r="1.5" />
    <circle cx="13" cy="10" r="1.5" />
    <circle cx="7" cy="15" r="1.5" />
    <circle cx="13" cy="15" r="1.5" />
  </svg>
);

interface DraggedState {
  type: 'category' | 'group';
  id: string;
  sourceGroupId?: string;
}

interface DropTargetState {
  type: 'category' | 'group' | 'group-header' | 'empty-group';
  id: string;
  position?: 'before' | 'after';
}

export const EditorFiltersSubView = () => {
  const queryClient = useQueryClient();

  // Drag and drop states
  const [draggedItem, setDraggedItem] = useState<DraggedState | null>(null);
  const [dropTarget, setDropTarget] = useState<DropTargetState | null>(null);

  // Group modal state
  const [isGroupModalOpen, setIsGroupModalOpen] = useState(false);
  const [editingGroup, setEditingGroup] = useState<CategoryGroupDto | null>(null);
  const [groupName, setGroupName] = useState('');

  // Category modal state
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<CategoryDto | null>(null);
  const [categoryName, setCategoryName] = useState('');
  const [categoryGroupId, setCategoryGroupId] = useState('');
  const [categoryIcon, setCategoryIcon] = useState('book');
  const [categoryDescription, setCategoryDescription] = useState('');

  // Deletion modals & error state
  const [deletingGroup, setDeletingGroup] = useState<CategoryGroupDto | null>(null);
  const [deletingCategory, setDeletingCategory] = useState<CategoryDto | null>(null);
  const [deletionError, setDeletionError] = useState<string | null>(null);

  // Queries
  const { data: categoryGroups, isLoading: areGroupsLoading } = useCategoryGroups();
  const { data: categories, isLoading: areCategoriesLoading } = useCategories();

  // Mutations
  const createGroup = useCreateCategoryGroup();
  const updateGroup = useUpdateCategoryGroup();
  const reorderGroups = useReorderCategoryGroups();
  const deleteGroup = useDeleteCategoryGroup();

  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();
  const reorderCategories = useReorderCategories();
  const deleteCategory = useDeleteCategory();

  const notifyEditor = useUiState((state) => state.notifyEditor);

  // Sorted Category Groups
  const sortedGroups = useMemo(() => {
    return [...(categoryGroups ?? [])].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  }, [categoryGroups]);

  // Categories by Group (sorted by order)
  const categoriesByGroup = useMemo(() => {
    const map: Record<string, CategoryDto[]> = {};
    (categories ?? []).forEach((cat) => {
      if (!map[cat.categoryGroupId]) {
        map[cat.categoryGroupId] = [];
      }
      map[cat.categoryGroupId].push(cat);
    });

    Object.keys(map).forEach((gId) => {
      map[gId].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
    });

    return map;
  }, [categories]);

  // Group Handlers
  const handleOpenAddGroup = () => {
    setEditingGroup(null);
    setGroupName('');
    setIsGroupModalOpen(true);
  };

  const handleOpenEditGroup = (group: CategoryGroupDto) => {
    setEditingGroup(group);
    setGroupName(group.name);
    setIsGroupModalOpen(true);
  };

  const handleSaveGroup = () => {
    if (!groupName.trim()) return;

    const gName = groupName.trim();
    if (editingGroup) {
      updateGroup.mutate(
        {
          id: editingGroup.id,
          payload: { name: gName },
        },
        {
          onSuccess: () => {
            setIsGroupModalOpen(false);
            notifyEditor(`Grupo "${gName}" actualizado con éxito.`);
          },
        },
      );
    } else {
      createGroup.mutate(
        {
          name: gName,
          order: sortedGroups.length + 1,
        },
        {
          onSuccess: () => {
            setIsGroupModalOpen(false);
            notifyEditor(`Grupo "${gName}" creado con éxito.`);
          },
        },
      );
    }
  };

  const handleDeleteGroup = () => {
    if (!deletingGroup) return;
    setDeletionError(null);

    const gName = deletingGroup.name;
    deleteGroup.mutate(deletingGroup.id, {
      onSuccess: () => {
        setDeletingGroup(null);
        notifyEditor(`Grupo "${gName}" eliminado.`);
      },
      onError: (err) => {
        setDeletionError(
          err.message || 'No se pudo eliminar el grupo.',
        );
      },
    });
  };

  // Category Handlers
  const handleOpenAddCategory = (preselectedGroupId?: string) => {
    setEditingCategory(null);
    setCategoryName('');
    setCategoryGroupId(preselectedGroupId || sortedGroups[0]?.id || '');
    setCategoryIcon('book');
    setCategoryDescription('');
    setIsCategoryModalOpen(true);
  };

  const handleOpenEditCategory = (cat: CategoryDto) => {
    setEditingCategory(cat);
    setCategoryName(cat.name);
    setCategoryGroupId(cat.categoryGroupId);
    setCategoryIcon(cat.icon || 'book');
    setCategoryDescription(cat.description || '');
    setIsCategoryModalOpen(true);
  };

  const handleSaveCategory = () => {
    if (!categoryName.trim() || !categoryGroupId) return;

    const cName = categoryName.trim();
    if (editingCategory) {
      updateCategory.mutate(
        {
          id: editingCategory.id,
          payload: {
            categoryGroupId,
            name: cName,
            icon: categoryIcon.trim() || 'book',
            description: categoryDescription.trim() || null,
          },
        },
        {
          onSuccess: () => {
            setIsCategoryModalOpen(false);
            notifyEditor(`Filtro "${cName}" actualizado con éxito.`);
          },
        },
      );
    } else {
      const currentCount = (categoriesByGroup[categoryGroupId] || []).length;
      createCategory.mutate(
        {
          categoryGroupId,
          name: cName,
          icon: categoryIcon.trim() || 'book',
          description: categoryDescription.trim() || null,
          order: currentCount + 1,
        },
        {
          onSuccess: () => {
            setIsCategoryModalOpen(false);
            notifyEditor(`Filtro "${cName}" creado con éxito.`);
          },
        },
      );
    }
  };

  const handleDeleteCategory = () => {
    if (!deletingCategory) return;
    setDeletionError(null);

    const cName = deletingCategory.name;
    deleteCategory.mutate(deletingCategory.id, {
      onSuccess: () => {
        setDeletingCategory(null);
        notifyEditor(`Filtro "${cName}" eliminado.`);
      },
      onError: (err) => {
        setDeletionError(
          err.message || 'No se pudo eliminar el filtro.',
        );
      },
    });
  };

  // ==================== DRAG AND DROP REORDER LOGIC ====================

  const handleCategoryDrop = (
    sourceCatId: string,
    targetCatId: string,
    targetGroupId: string,
    position: 'before' | 'after',
  ) => {
    const allCats = categories ?? [];
    const sourceCat = allCats.find((c) => c.id === sourceCatId);
    const targetCat = allCats.find((c) => c.id === targetCatId);
    if (!sourceCat || !targetCat) return;

    const sourceGroupId = sourceCat.categoryGroupId;

    if (sourceGroupId === targetGroupId) {
      const groupCats = [...(categoriesByGroup[sourceGroupId] || [])];
      const sourceIdx = groupCats.findIndex((c) => c.id === sourceCatId);
      if (sourceIdx === -1) return;

      const [removed] = groupCats.splice(sourceIdx, 1);
      let targetIdx = groupCats.findIndex((c) => c.id === targetCatId);
      if (targetIdx === -1) {
        groupCats.push(removed);
      } else {
        if (position === 'after') {
          targetIdx += 1;
        }
        groupCats.splice(targetIdx, 0, removed);
      }

      const payload = groupCats.map((c, idx) => ({
        id: c.id,
        order: idx + 1,
      }));

      const updatedList = allCats.map((c) => {
        const item = payload.find((p) => p.id === c.id);
        return item ? { ...c, order: item.order } : c;
      });
      queryClient.setQueryData(queryKeys.categories, updatedList);

      reorderCategories.mutate(payload);
    } else {
      const targetGroupCats = [...(categoriesByGroup[targetGroupId] || [])];
      let targetIdx = targetGroupCats.findIndex((c) => c.id === targetCatId);
      if (targetIdx === -1) {
        targetGroupCats.push(sourceCat);
      } else {
        if (position === 'after') {
          targetIdx += 1;
        }
        targetGroupCats.splice(targetIdx, 0, sourceCat);
      }

      const newOrder = targetIdx + 1;

      const updatedList = allCats.map((c) => {
        if (c.id === sourceCat.id) {
          return { ...c, categoryGroupId: targetGroupId, order: newOrder };
        }
        return c;
      });
      queryClient.setQueryData(queryKeys.categories, updatedList);

      updateCategory.mutate(
        {
          id: sourceCat.id,
          payload: {
            categoryGroupId: targetGroupId,
            name: sourceCat.name,
            icon: sourceCat.icon,
            description: sourceCat.description,
            order: newOrder,
          },
        },
        {
          onSuccess: () => {
            const payload = targetGroupCats.map((c, idx) => ({
              id: c.id,
              order: idx + 1,
            }));
            reorderCategories.mutate(payload);
          },
        },
      );
    }
  };

  const handleCategoryDropOnGroup = (sourceCatId: string, targetGroupId: string) => {
    const allCats = categories ?? [];
    const sourceCat = allCats.find((c) => c.id === sourceCatId);
    if (!sourceCat) return;

    const targetGroupCats = (categoriesByGroup[targetGroupId] || []).filter(
      (c) => c.id !== sourceCatId,
    );
    targetGroupCats.push(sourceCat);

    const newOrder = targetGroupCats.length;

    const updatedList = allCats.map((c) => {
      if (c.id === sourceCat.id) {
        return { ...c, categoryGroupId: targetGroupId, order: newOrder };
      }
      return c;
    });
    queryClient.setQueryData(queryKeys.categories, updatedList);

    updateCategory.mutate(
      {
        id: sourceCat.id,
        payload: {
          categoryGroupId: targetGroupId,
          name: sourceCat.name,
          icon: sourceCat.icon,
          description: sourceCat.description,
          order: newOrder,
        },
      },
      {
        onSuccess: () => {
          const payload = targetGroupCats.map((c, idx) => ({
            id: c.id,
            order: idx + 1,
          }));
          reorderCategories.mutate(payload);
        },
      },
    );
  };

  const handleGroupDrop = (
    sourceGroupId: string,
    targetGroupId: string,
    position: 'before' | 'after',
  ) => {
    if (sourceGroupId === targetGroupId) return;

    const groups = [...sortedGroups];
    const sourceIdx = groups.findIndex((g) => g.id === sourceGroupId);
    if (sourceIdx === -1) return;

    const [removed] = groups.splice(sourceIdx, 1);
    let targetIdx = groups.findIndex((g) => g.id === targetGroupId);
    if (targetIdx === -1) {
      groups.push(removed);
    } else {
      if (position === 'after') {
        targetIdx += 1;
      }
      groups.splice(targetIdx, 0, removed);
    }

    const payload = groups.map((g, idx) => ({
      id: g.id,
      order: idx + 1,
    }));

    queryClient.setQueryData(
      queryKeys.categoryGroups,
      groups.map((g, idx) => ({ ...g, order: idx + 1 })),
    );

    reorderGroups.mutate(payload);
  };

  const isDataLoading = areGroupsLoading || areCategoriesLoading;

  return (
    <div className="w-full h-full bg-transparent p-6 flex flex-col gap-4 overflow-hidden">
      {/* Top Action Bar */}
      <div className="flex items-center justify-end gap-3 flex-shrink-0">
        <Button
          size="lg"
          variant="outline"
          color="white"
          className="!w-auto px-5 py-2.5 flex items-center gap-2 border-white/20 text-white hover:bg-white/10 text-sm font-bold"
          onClick={handleOpenAddGroup}
        >
          <PlusIcon className="w-4 h-4" />
          Nuevo grupo
        </Button>

        <Button
          size="lg"
          color="blue"
          className="!w-auto px-6 py-2.5 flex items-center gap-2 text-sm font-bold"
          onClick={() => handleOpenAddCategory()}
          disabled={sortedGroups.length === 0}
        >
          <PlusIcon className="w-4 h-4" />
          Nuevo filtro
        </Button>
      </div>

      {/* Main Single-Panel Container */}
      <div className="flex-1 min-h-0 w-full max-w-6xl mx-auto flex flex-col">
        <Panel
          withUctBorder={false}
          outerClassName="!w-full !h-full min-h-0 shadow-lg"
          innerClassName="p-6 md:p-8 flex flex-col gap-4 h-full min-h-0"
        >
          {isDataLoading && (
            <div className="flex flex-1 items-center justify-center text-base text-gray-500">
              Cargando filtros y grupos...
            </div>
          )}

          {!isDataLoading && sortedGroups.length === 0 && (
            <div className="flex flex-1 flex-col items-center justify-center text-center p-8">
              <FilterIcon className="w-14 h-14 text-gray-400 mb-2 opacity-40" />
              <h3 className="text-lg font-bold text-gray-700">No hay grupos de filtros creados</h3>
              <p className="text-sm text-gray-500 mt-1 max-w-sm">
                Crea un grupo de filtros primero para poder agrupar tus categorías de filtros del mapa.
              </p>
              <Button
                size="md"
                color="blue"
                className="!w-auto mt-4"
                onClick={handleOpenAddGroup}
              >
                Crear primer grupo
              </Button>
            </div>
          )}

          {/* Unified Tree List: gap-3 para mantener la separación constante entre grupos */}
          {!isDataLoading && sortedGroups.length > 0 && (
            <div className="flex flex-1 min-h-0 flex-col gap-3 overflow-y-auto pr-2">
              {sortedGroups.map((group) => {
                const groupCategories = categoriesByGroup[group.id] || [];
                const isGroupDragged = draggedItem?.type === 'group' && draggedItem.id === group.id;

                const isDropTargetGroupBefore =
                  dropTarget?.type === 'group' &&
                  dropTarget.id === group.id &&
                  dropTarget.position === 'before';

                const isDropTargetGroupAfter =
                  dropTarget?.type === 'group' &&
                  dropTarget.id === group.id &&
                  dropTarget.position === 'after';

                const isDropTargetGroupHeader =
                  dropTarget?.type === 'group-header' && dropTarget.id === group.id;

                return (
                  <div
                    key={group.id}
                    className={`flex flex-col transition-opacity ${
                      isGroupDragged ? 'opacity-30' : 'opacity-100'
                    }`}
                  >
                    {/* Blue insertion line for group reordering (BEFORE) */}
                    {isDropTargetGroupBefore && (
                      <div className="h-1 bg-page-blue rounded-full my-1 animate-pulse" />
                    )}

                    {/* Group Header Row */}
                    <div
                      draggable
                      onDragStart={(e) => {
                        e.stopPropagation();
                        setDraggedItem({ type: 'group', id: group.id });
                        e.dataTransfer.effectAllowed = 'move';
                        e.dataTransfer.setData('text/plain', group.id);
                      }}
                      onDragEnd={() => {
                        setDraggedItem(null);
                        setDropTarget(null);
                      }}
                      onDragOver={(e) => {
                        e.preventDefault();
                        e.stopPropagation();
                        e.dataTransfer.dropEffect = 'move';

                        if (draggedItem?.type === 'group') {
                          if (draggedItem.id === group.id) return;
                          const rect = e.currentTarget.getBoundingClientRect();
                          const isAbove = e.clientY < rect.top + rect.height / 2;
                          setDropTarget({
                            type: 'group',
                            id: group.id,
                            position: isAbove ? 'before' : 'after',
                          });
                        } else if (draggedItem?.type === 'category') {
                          setDropTarget({
                            type: 'group-header',
                            id: group.id,
                          });
                        }
                      }}
                      onDrop={(e) => {
                        e.preventDefault();
                        e.stopPropagation();

                        if (draggedItem?.type === 'group') {
                          const rect = e.currentTarget.getBoundingClientRect();
                          const position = e.clientY < rect.top + rect.height / 2 ? 'before' : 'after';
                          handleGroupDrop(draggedItem.id, group.id, position);
                        } else if (draggedItem?.type === 'category') {
                          handleCategoryDropOnGroup(draggedItem.id, group.id);
                        }

                        setDraggedItem(null);
                        setDropTarget(null);
                      }}
                      className={`flex items-center justify-between py-2 px-3.5 rounded-xl cursor-grab active:cursor-grabbing select-none group/group transition-colors ${
                        isDropTargetGroupHeader
                          ? 'bg-blue-100/70 border border-page-blue text-page-blue'
                          : 'hover:bg-gray-100/70'
                      }`}
                    >
                      {/* Left: Grip & Group Name */}
                      <div className="flex items-center gap-3.5 min-w-0">
                        <GripIcon className="w-5 h-5 text-gray-400 group-hover/group:text-gray-600 flex-shrink-0" />

                        <span className="text-base font-black text-gray-800 tracking-wider uppercase truncate">
                          {group.name}
                        </span>
                      </div>

                      {/* Right: Larger Edit/Delete Actions */}
                      <div className="flex items-center gap-2.5 opacity-80 group-hover/group:opacity-100 transition-opacity">
                        <SquareButton
                          type="button"
                          title="Añadir filtro a este grupo"
                          className="!w-11 !h-11 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-blue hover:bg-blue-50/70 transition-colors [&>span]:!w-5 [&>span]:!h-5"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleOpenAddCategory(group.id);
                          }}
                        >
                          <PlusIcon className="w-5 h-5 pointer-events-none text-page-blue" />
                        </SquareButton>

                        <SquareButton
                          type="button"
                          title="Editar nombre del grupo"
                          className="!w-11 !h-11 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-blue hover:bg-blue-50/70 transition-colors [&>span]:!w-5 [&>span]:!h-5"
                          onClick={() => handleOpenEditGroup(group)}
                        >
                          <PencilIcon className="w-5 h-5 pointer-events-none text-page-blue" />
                        </SquareButton>

                        <SquareButton
                          type="button"
                          title="Eliminar grupo"
                          className="!w-11 !h-11 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-red hover:bg-red-50/70 active:!bg-page-red transition-colors [&>span]:!w-5 [&>span]:!h-5"
                          onClick={() => setDeletingGroup(group)}
                        >
                          <TrashIcon className="w-5 h-5 pointer-events-none text-page-red" />
                        </SquareButton>
                      </div>
                    </div>

                    {/* Filter Items: mt-1 y gap-1 para un ritmo visual regular */}
                    {groupCategories.length > 0 && (
                      <div className="flex flex-col gap-1 mt-1 ml-6 border-l-2 border-gray-200 pl-4">
                        {groupCategories.map((cat) => {
                          const isCatDragged =
                            draggedItem?.type === 'category' && draggedItem.id === cat.id;

                          const isDropTargetCatBefore =
                            dropTarget?.type === 'category' &&
                            dropTarget.id === cat.id &&
                            dropTarget.position === 'before';

                          const isDropTargetCatAfter =
                            dropTarget?.type === 'category' &&
                            dropTarget.id === cat.id &&
                            dropTarget.position === 'after';

                          return (
                            <div key={cat.id} className="flex flex-col">
                              {/* Blue drop indicator line (BEFORE) */}
                              {isDropTargetCatBefore && (
                                <div className="h-0.5 bg-page-blue rounded-full my-0.5 mx-1 animate-pulse" />
                              )}

                              {/* Category Item Row */}
                              <div
                                draggable
                                onDragStart={(e) => {
                                  e.stopPropagation();
                                  setDraggedItem({
                                    type: 'category',
                                    id: cat.id,
                                    sourceGroupId: cat.categoryGroupId,
                                  });
                                  e.dataTransfer.effectAllowed = 'move';
                                  e.dataTransfer.setData('text/plain', cat.id);
                                }}
                                onDragEnd={() => {
                                  setDraggedItem(null);
                                  setDropTarget(null);
                                }}
                                onDragOver={(e) => {
                                  if (draggedItem?.type !== 'category') return;
                                  if (draggedItem.id === cat.id) return;

                                  e.preventDefault();
                                  e.stopPropagation();
                                  e.dataTransfer.dropEffect = 'move';

                                  const rect = e.currentTarget.getBoundingClientRect();
                                  const isAbove = e.clientY < rect.top + rect.height / 2;
                                  setDropTarget({
                                    type: 'category',
                                    id: cat.id,
                                    position: isAbove ? 'before' : 'after',
                                  });
                                }}
                                onDrop={(e) => {
                                  if (draggedItem?.type !== 'category') return;
                                  e.preventDefault();
                                  e.stopPropagation();

                                  const rect = e.currentTarget.getBoundingClientRect();
                                  const position = e.clientY < rect.top + rect.height / 2 ? 'before' : 'after';
                                  handleCategoryDrop(draggedItem.id, cat.id, group.id, position);

                                  setDraggedItem(null);
                                  setDropTarget(null);
                                }}
                                className={`flex items-center justify-between py-2 px-3.5 rounded-xl cursor-grab active:cursor-grabbing select-none group/item transition-colors ${
                                  isCatDragged
                                    ? 'opacity-30 bg-gray-100'
                                    : 'hover:bg-gray-100/70'
                                }`}
                              >
                                {/* Left: Grip, Icon Badge, Name, Description */}
                                <div className="flex items-center gap-3.5 min-w-0 pr-3">
                                  <GripIcon className="w-4.5 h-4.5 text-gray-400 group-hover/item:text-gray-600 flex-shrink-0" />

                                  <div className="w-9 h-9 rounded-xl bg-blue-50 border border-blue-100 flex items-center justify-center text-page-blue flex-shrink-0">
                                    <CategoryIcon icon={cat.icon} className="w-5 h-5" />
                                  </div>

                                  <span className="text-base md:text-lg font-bold text-gray-800 truncate">
                                    {cat.name}
                                  </span>

                                  {cat.description && (
                                    <span className="text-sm md:text-base text-gray-400 truncate hidden md:inline ml-2 font-normal">
                                      — {cat.description}
                                    </span>
                                  )}
                                </div>

                                {/* Right: Larger Actions */}
                                <div className="flex items-center gap-2 opacity-0 group-hover/item:opacity-100 transition-opacity">
                                  <SquareButton
                                    type="button"
                                    title="Editar filtro"
                                    className="!w-10 !h-10 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-blue hover:bg-blue-50/70 transition-colors [&>span]:!w-5 [&>span]:!h-5"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleOpenEditCategory(cat);
                                    }}
                                  >
                                    <PencilIcon className="w-5 h-5 pointer-events-none text-page-blue" />
                                  </SquareButton>

                                  <SquareButton
                                    type="button"
                                    title="Eliminar filtro"
                                    className="!w-10 !h-10 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-red hover:bg-red-50/70 active:!bg-page-red transition-colors [&>span]:!w-5 [&>span]:!h-5"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      setDeletingCategory(cat);
                                    }}
                                  >
                                    <TrashIcon className="w-5 h-5 pointer-events-none text-page-red" />
                                  </SquareButton>
                                </div>
                              </div>

                              {/* Blue drop indicator line (AFTER) */}
                              {isDropTargetCatAfter && (
                                <div className="h-0.5 bg-page-blue rounded-full my-0.5 mx-1 animate-pulse" />
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}

                    {/* Blue insertion line for group reordering (AFTER) */}
                    {isDropTargetGroupAfter && (
                      <div className="h-1 bg-page-blue rounded-full my-1 animate-pulse" />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </Panel>
      </div>

      {/* Modal: Create / Edit Category Group */}
      <ModalOverlay isOpen={isGroupModalOpen} onClose={() => setIsGroupModalOpen(false)}>
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              {editingGroup ? 'Editar grupo de filtros' : 'Nuevo grupo de filtros'}
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre del grupo"
              placeholder="Ej: Espacios Académicos, Servicios"
              value={groupName}
              onChange={(e) => setGroupName(e.target.value)}
            />

            {(createGroup.isError || updateGroup.isError) && (
              <span className="text-xs text-page-red">
                {createGroup.error?.message || updateGroup.error?.message}
              </span>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <Button
              color="blue"
              className="flex-1 !w-auto"
              onClick={handleSaveGroup}
              disabled={!groupName.trim() || createGroup.isPending || updateGroup.isPending}
            >
              {createGroup.isPending || updateGroup.isPending ? 'Guardando...' : 'Guardar grupo'}
            </Button>
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsGroupModalOpen(false)}
            >
              Cancelar
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Create / Edit Category (Filter) */}
      <ModalOverlay isOpen={isCategoryModalOpen} onClose={() => setIsCategoryModalOpen(false)}>
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              {editingCategory ? 'Editar filtro' : 'Nuevo filtro'}
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre del filtro"
              placeholder="Ej: Sala de Clases, Laboratorio"
              value={categoryName}
              onChange={(e) => setCategoryName(e.target.value)}
            />

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Grupo asignado</label>
              <select
                className="w-full rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                value={categoryGroupId}
                onChange={(e) => setCategoryGroupId(e.target.value)}
              >
                {sortedGroups.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.name}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Ícono</label>
              <div className="flex items-center gap-2.5">
                <div className="w-11 h-11 rounded-2xl bg-blue-50 border border-blue-100 flex items-center justify-center text-page-blue shrink-0">
                  <CategoryIcon icon={categoryIcon} className="w-5 h-5" />
                </div>
                <select
                  className="flex-1 rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue"
                  value={categoryIcon}
                  onChange={(e) => setCategoryIcon(e.target.value)}
                >
                  {PRESET_ICONS.map((ico) => (
                    <option key={ico.value} value={ico.value}>
                      {ico.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <Input
              label="Descripción (opcional)"
              placeholder="Breve descripción para el usuario"
              value={categoryDescription}
              onChange={(e) => setCategoryDescription(e.target.value)}
            />

            {(createCategory.isError || updateCategory.isError) && (
              <span className="text-xs text-page-red">
                {createCategory.error?.message || updateCategory.error?.message}
              </span>
            )}
          </div>

          <div className="flex gap-2 pt-2 border-t border-gray-100">
            <Button
              color="blue"
              className="flex-1 !w-auto"
              onClick={handleSaveCategory}
              disabled={
                !categoryName.trim() ||
                !categoryGroupId ||
                createCategory.isPending ||
                updateCategory.isPending
              }
            >
              {createCategory.isPending || updateCategory.isPending
                ? 'Guardando...'
                : 'Guardar filtro'}
            </Button>
            <Button
              variant="outline"
              color="gray"
              className="!w-auto px-4"
              onClick={() => setIsCategoryModalOpen(false)}
            >
              Cancelar
            </Button>
          </div>
        </div>
      </ModalOverlay>

      {/* Modal: Delete Group Confirmation */}
      <ModalOverlay
        isOpen={!!deletingGroup}
        onClose={() => {
          setDeletingGroup(null);
          setDeletionError(null);
        }}
      >
        {(() => {
          const groupCount = (categoriesByGroup[deletingGroup?.id || ''] || []).length;

          const confirmDescription =
            groupCount > 0
              ? `¿Estás seguro de que deseas eliminar el grupo "${deletingGroup?.name}"? Esta acción eliminará el grupo junto con sus ${groupCount} filtro(s) asociados en cascada, y los edificios o salas quedarán sin categoría. Esta acción no se puede deshacer.`
              : `¿Estás seguro de que deseas eliminar el grupo "${deletingGroup?.name}"? Esta acción no se puede deshacer.`;

          return (
            <TimedActionCard
              title="Eliminar grupo de filtros"
              description={deletionError || confirmDescription}
              initialDurationMs={deletionError ? 0 : 1500}
              options={
                deletionError
                  ? [
                      {
                        label: 'Entendido',
                        color: 'gray',
                        onClick: () => {
                          setDeletingGroup(null);
                          setDeletionError(null);
                        },
                      },
                    ]
                  : [
                      {
                        label: 'Cancelar',
                        color: 'gray',
                        onClick: () => {
                          setDeletingGroup(null);
                          setDeletionError(null);
                        },
                      },
                      {
                        label: 'Sí, eliminar',
                        color: 'red',
                        onClick: handleDeleteGroup,
                      },
                    ]
              }
            />
          );
        })()}
      </ModalOverlay>

      {/* Modal: Delete Category Confirmation */}
      <ModalOverlay
        isOpen={!!deletingCategory}
        onClose={() => {
          setDeletingCategory(null);
          setDeletionError(null);
        }}
      >
        <TimedActionCard
          title={deletionError ? 'No se pudo eliminar el filtro' : 'Eliminar filtro'}
          description={
            deletionError ||
            `¿Estás seguro de que deseas eliminar el filtro "${deletingCategory?.name}"? Los edificios y salas que tengan este filtro asignado quedarán sin categoría. Esta acción no se puede deshacer.`
          }
          initialDurationMs={deletionError ? 0 : 1500}
          options={
            deletionError
              ? [
                  {
                    label: 'Entendido',
                    color: 'gray',
                    onClick: () => {
                      setDeletingCategory(null);
                      setDeletionError(null);
                    },
                  },
                ]
              : [
                  {
                    label: 'Cancelar',
                    color: 'gray',
                    onClick: () => {
                      setDeletingCategory(null);
                      setDeletionError(null);
                    },
                  },
                  {
                    label: 'Sí, eliminar',
                    color: 'red',
                    onClick: handleDeleteCategory,
                  },
                ]
          }
        />
      </ModalOverlay>
    </div>
  );
};
