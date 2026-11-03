import { useMemo, useState } from 'react';
import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';
import { CheckboxItem } from '../../components/ui/CheckboxItem';
import { CategoryIcon } from '../../components/ui/CategoryIcon';
import { useCategoryGroups, useCategories } from '../../hooks/useCampus';
import FilterIcon from '../../assets/svg/icons/icon_filter.svg?react';
import type { CategoryDto } from '../../dtos/campus/CategoryDto';

interface MapSidePanelProps {
  onClose: () => void;
}

export const MapSidePanel = ({ onClose }: MapSidePanelProps) => {
  const [selectedCategoryIds, setSelectedCategoryIds] = useState<string[]>([]);

  const { data: categoryGroups, isLoading: areGroupsLoading } = useCategoryGroups();
  const { data: categories, isLoading: areCategoriesLoading } = useCategories();

  const sortedGroups = useMemo(() => {
    return [...(categoryGroups ?? [])].sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
  }, [categoryGroups]);

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

  const handleToggleCategory = (id: string) => {
    setSelectedCategoryIds((prev) =>
      prev.includes(id) ? prev.filter((catId) => catId !== id) : [...prev, id],
    );
  };

  const isLoading = areGroupsLoading || areCategoriesLoading;

  return (
    <Panel
      withUctBorder={false}
      size="lg"
      outerClassName="w-full !h-full min-h-0"
      innerClassName="p-5 h-full flex flex-col min-h-0"
    >
      {/* Header */}
      <div className="flex items-center justify-between gap-2 flex-shrink-0">
        <div className="flex items-center gap-3">
          <FilterIcon className="w-7 h-7 shrink-0 text-page-blue" />
          <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
            Filtros
          </h2>
        </div>

        <div className="flex items-center gap-2">
          {selectedCategoryIds.length > 0 && (
            <button
              type="button"
              onClick={() => setSelectedCategoryIds([])}
              className="text-xs font-bold text-page-blue hover:underline cursor-pointer"
            >
              Limpiar ({selectedCategoryIds.length})
            </button>
          )}
          <CloseButton variant="ghost" size="lg" onClick={onClose} />
        </div>
      </div>

      {/* Categories grouped by Category Group */}
      <div className="flex-1 min-h-0 overflow-y-auto pr-1 flex flex-col gap-4 mt-4">
        {isLoading && (
          <span className="text-sm text-gray-500 py-6 text-center">Cargando filtros...</span>
        )}

        {!isLoading && sortedGroups.length === 0 && (
          <span className="text-sm text-gray-500 py-6 text-center">
            No hay filtros configurados.
          </span>
        )}

        {!isLoading &&
          sortedGroups.map((group) => {
            const groupCats = categoriesByGroup[group.id] || [];
            if (groupCats.length === 0) return null;

            return (
              <div key={group.id} className="flex flex-col gap-2">
                <span className="text-xs font-black text-gray-500 uppercase tracking-wider px-1">
                  {group.name}
                </span>

                <div className="flex flex-col gap-2">
                  {groupCats.map((cat) => (
                    <CheckboxItem
                      key={cat.id}
                      label={cat.name}
                      desc={cat.description || undefined}
                      icon={<CategoryIcon icon={cat.icon} className="w-5 h-5 text-page-dark" />}
                      checked={selectedCategoryIds.includes(cat.id)}
                      onChange={() => handleToggleCategory(cat.id)}
                      className="!max-w-none"
                    />
                  ))}
                </div>
              </div>
            );
          })}
      </div>
    </Panel>
  );
};
