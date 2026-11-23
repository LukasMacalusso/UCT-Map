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
  useCategories,
  useCreateCategory,
  useUpdateCategory,
  useReorderCategories,
  useDeleteCategory,
} from '../../hooks/useCampus';
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

interface DropTargetState {
  id: string;
  position: 'before' | 'after';
}

export const EditorFiltersSubView = () => {
  const queryClient = useQueryClient();

  // Drag and drop state
  const [draggedCategoryId, setDraggedCategoryId] = useState<string | null>(null);
  const [dropTarget, setDropTarget] = useState<DropTargetState | null>(null);

  // Category modal state
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<CategoryDto | null>(null);
  const [categoryName, setCategoryName] = useState('');
  const [categoryIcon, setCategoryIcon] = useState('book');
  const [categoryDescription, setCategoryDescription] = useState('');

  // Deletion modal state
  const [deletingCategory, setDeletingCategory] = useState<CategoryDto | null>(null);
  const [deletionError, setDeletionError] = useState<string | null>(null);

  // Queries & Mutations
  const { data: categories, isLoading: isCategoriesLoading } = useCategories();
  const createCategory = useCreateCategory();
  const updateCategory = useUpdateCategory();
  const reorderCategories = useReorderCategories();
  const deleteCategory = useDeleteCategory();

  const notifyEditor = useUiState((state) => state.notifyEditor);

  // Sorted Categories by order
  const sortedCategories = useMemo(() => {
    return [...(categories ?? [])].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  }, [categories]);

  // Modal Handlers
  const handleOpenAddCategory = () => {
    setEditingCategory(null);
    setCategoryName('');
    setCategoryIcon('book');
    setCategoryDescription('');
    setIsCategoryModalOpen(true);
  };

  const handleOpenEditCategory = (cat: CategoryDto) => {
    setEditingCategory(cat);
    setCategoryName(cat.name);
    setCategoryIcon(cat.icon || 'book');
    setCategoryDescription(cat.description || '');
    setIsCategoryModalOpen(true);
  };

  const handleSaveCategory = () => {
    if (!categoryName.trim()) return;

    if (editingCategory) {
      updateCategory.mutate(
        {
          id: editingCategory.id,
          payload: {
            name: categoryName.trim(),
            icon: categoryIcon,
            description: categoryDescription.trim() || null,
            order: editingCategory.order,
          },
        },
        {
          onSuccess: () => {
            setIsCategoryModalOpen(false);
            notifyEditor(`Filtro "${categoryName.trim()}" actualizado.`);
          },
        },
      );
    } else {
      const nextOrder = sortedCategories.length + 1;
      createCategory.mutate(
        {
          name: categoryName.trim(),
          icon: categoryIcon,
          description: categoryDescription.trim() || null,
          order: nextOrder,
        },
        {
          onSuccess: (newCat) => {
            setIsCategoryModalOpen(false);
            notifyEditor(`Filtro "${newCat.name}" creado con éxito.`);
          },
        },
      );
    }
  };

  const handleDeleteCategory = () => {
    if (!deletingCategory) return;
    const catName = deletingCategory.name;

    deleteCategory.mutate(deletingCategory.id, {
      onSuccess: () => {
        setDeletingCategory(null);
        setDeletionError(null);
        notifyEditor(`Filtro "${catName}" eliminado.`);
      },
      onError: (err) => {
        setDeletionError(
          err.message || 'No se pudo eliminar el filtro. Puede estar asociado a edificios o salas.',
        );
      },
    });
  };

  // Drag and Drop Reordering Handlers
  const handleDragStart = (e: React.DragEvent, id: string) => {
    e.dataTransfer.setData('text/plain', id);
    e.dataTransfer.effectAllowed = 'move';
    setDraggedCategoryId(id);
  };

  const handleDragOver = (e: React.DragEvent, targetId: string) => {
    e.preventDefault();
    e.stopPropagation();

    if (!draggedCategoryId || draggedCategoryId === targetId) {
      return;
    }

    const rect = e.currentTarget.getBoundingClientRect();
    const midY = rect.top + rect.height / 2;
    const position = e.clientY < midY ? 'before' : 'after';

    if (dropTarget?.id !== targetId || dropTarget?.position !== position) {
      setDropTarget({ id: targetId, position });
    }
  };

  const handleDrop = (e: React.DragEvent, targetId: string) => {
    e.preventDefault();
    e.stopPropagation();

    if (!draggedCategoryId || draggedCategoryId === targetId) {
      setDraggedCategoryId(null);
      setDropTarget(null);
      return;
    }

    const currentList = [...sortedCategories];
    const sourceIdx = currentList.findIndex((c) => c.id === draggedCategoryId);
    const targetIdx = currentList.findIndex((c) => c.id === targetId);

    if (sourceIdx === -1 || targetIdx === -1) {
      setDraggedCategoryId(null);
      setDropTarget(null);
      return;
    }

    const [moved] = currentList.splice(sourceIdx, 1);
    const insertionIdx = dropTarget?.position === 'before' ? targetIdx : targetIdx + 1;
    currentList.splice(insertionIdx > sourceIdx ? insertionIdx - 1 : insertionIdx, 0, moved);

    const payload = currentList.map((item, idx) => ({
      id: item.id,
      order: idx + 1,
    }));

    // Optimistic cache update
    queryClient.setQueryData(
      queryKeys.categories,
      currentList.map((c, idx) => ({ ...c, order: idx + 1 })),
    );

    reorderCategories.mutate(payload);

    setDraggedCategoryId(null);
    setDropTarget(null);
  };

  const handleDragEnd = () => {
    setDraggedCategoryId(null);
    setDropTarget(null);
  };

  return (
    <div className="w-full h-full bg-transparent p-6 flex flex-col overflow-hidden">
      {/* Main Single-Panel Container */}
      <div className="flex-1 min-h-0 w-full max-w-4xl mx-auto flex flex-col">
        <Panel
          withUctBorder={false}
          outerClassName="!w-full !h-full min-h-0 shadow-lg"
          innerClassName="p-6 md:p-8 flex flex-col gap-4 h-full min-h-0"
        >
          <div className="flex items-center justify-between pb-3 border-b border-gray-100 flex-shrink-0">
            <div className="flex flex-col">
              <h2 className="text-xl font-extrabold text-gray-800 uppercase tracking-tight">
                Filtros del mapa
              </h2>
              <span className="text-sm text-gray-500 font-medium">
                {isCategoriesLoading
                  ? 'Cargando filtros...'
                  : `${sortedCategories.length} ${
                      sortedCategories.length === 1 ? 'filtro registrado' : 'filtros registrados'
                    }`}
              </span>
            </div>

            <Button
              size="md"
              color="blue"
              className="!w-auto px-5 py-2 flex items-center gap-2 text-sm font-bold"
              onClick={handleOpenAddCategory}
            >
              <PlusIcon className="w-4 h-4" />
              Nuevo filtro
            </Button>
          </div>

          {isCategoriesLoading && (
            <div className="flex flex-1 items-center justify-center text-base text-gray-500">
              Cargando filtros...
            </div>
          )}

          {!isCategoriesLoading && sortedCategories.length === 0 && (
            <div className="flex flex-1 flex-col items-center justify-center text-center p-8">
              <FilterIcon className="w-14 h-14 text-gray-400 mb-2 opacity-40" />
              <h3 className="text-lg font-bold text-gray-700">No hay filtros configurados</h3>
              <p className="text-sm text-gray-500 mt-1 max-w-sm">
                Crea filtros para categorizar tus edificios, estructuras y salas en el mapa interactivo.
              </p>
              <Button
                size="md"
                color="blue"
                className="!w-auto mt-4"
                onClick={handleOpenAddCategory}
              >
                Crear primer filtro
              </Button>
            </div>
          )}

          {/* Categories List */}
          {!isCategoriesLoading && sortedCategories.length > 0 && (
            <div className="flex flex-1 min-h-0 flex-col gap-2.5 overflow-y-auto pr-2">
              {sortedCategories.map((cat) => {
                const isItemDragged = draggedCategoryId === cat.id;
                const isDropTargetBefore =
                  dropTarget?.id === cat.id && dropTarget.position === 'before';
                const isDropTargetAfter =
                  dropTarget?.id === cat.id && dropTarget.position === 'after';

                return (
                  <div key={cat.id} className="flex flex-col">
                    {/* Blue drop indicator line (BEFORE) */}
                    {isDropTargetBefore && (
                      <div className="h-1 bg-page-blue rounded-full my-1 animate-pulse" />
                    )}

                    <div
                      draggable
                      onDragStart={(e) => handleDragStart(e, cat.id)}
                      onDragOver={(e) => handleDragOver(e, cat.id)}
                      onDrop={(e) => handleDrop(e, cat.id)}
                      onDragEnd={handleDragEnd}
                      className={`group/item flex items-center justify-between gap-3 p-3.5 rounded-2xl border border-gray-200 bg-white transition-all cursor-move select-none ${
                        isItemDragged
                          ? 'opacity-30 bg-gray-100'
                          : 'hover:border-gray-300 hover:shadow-xs'
                      }`}
                    >
                      {/* Left: Grip, Icon Badge, Name, Description */}
                      <div className="flex items-center gap-3.5 min-w-0 pr-3">
                        <GripIcon className="w-5 h-5 text-gray-400 group-hover/item:text-gray-600 flex-shrink-0" />

                        <div className="w-10 h-10 rounded-xl bg-page-blue flex items-center justify-center text-white flex-shrink-0 shadow-xs">
                          <CategoryIcon icon={cat.icon} className="w-5 h-5 text-white" />
                        </div>

                        <div className="flex flex-col min-w-0">
                          <span className="text-base font-bold text-gray-800 truncate">
                            {cat.name}
                          </span>
                          {cat.description && (
                            <span className="text-xs text-gray-400 truncate font-normal">
                              {cat.description}
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Right: Actions */}
                      <div className="flex items-center gap-1.5 flex-shrink-0">
                        <SquareButton
                          type="button"
                          title="Editar filtro"
                          className="!w-9 !h-9 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-blue transition-colors"
                          onClick={() => handleOpenEditCategory(cat)}
                        >
                          <PencilIcon className="w-4 h-4 pointer-events-none text-page-blue" />
                        </SquareButton>

                        <SquareButton
                          type="button"
                          title="Eliminar filtro"
                          className="!w-9 !h-9 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-red transition-colors"
                          onClick={() => setDeletingCategory(cat)}
                        >
                          <TrashIcon className="w-4 h-4 pointer-events-none text-page-red" />
                        </SquareButton>
                      </div>
                    </div>

                    {/* Blue drop indicator line (AFTER) */}
                    {isDropTargetAfter && (
                      <div className="h-1 bg-page-blue rounded-full my-1 animate-pulse" />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </Panel>
      </div>

      {/* Modal: Create or Edit Category */}
      <ModalOverlay
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
      >
        <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
          <div className="flex items-center justify-between pb-2 border-b border-gray-100">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              {editingCategory ? 'Editar filtro' : 'Nuevo filtro'}
            </h3>
          </div>

          <div className="flex flex-col gap-3">
            <Input
              label="Nombre del filtro"
              labelColor="text-gray-700"
              placeholder="Ej: Laboratorio, Baños, Biblioteca"
              value={categoryName}
              onChange={(e) => setCategoryName(e.target.value)}
            />

            <div className="flex flex-col gap-1.5">
              <label className="text-xs font-bold text-gray-700 uppercase">Ícono</label>
              <div className="flex items-center gap-2.5">
                <div className="w-11 h-11 rounded-2xl bg-page-blue flex items-center justify-center text-white shrink-0 shadow-xs">
                  <CategoryIcon icon={categoryIcon} className="w-5 h-5 text-white" />
                </div>
                <select
                  className="flex-1 rounded-2xl border border-gray-200 p-3 text-sm font-semibold text-gray-800 focus:outline-none focus:border-page-blue cursor-pointer"
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
              labelColor="text-gray-700"
              placeholder="Descripción breve de la categoría"
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
