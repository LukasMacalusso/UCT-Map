import type { StructureDto } from '../../dtos/campus/StructureDto';
import { useCampuses, useCategories } from '../../hooks/useCampus';
import { StructureDetailCard } from './StructureDetailCard';

interface ActiveStructureCardProps {
  structure: StructureDto | null;
  onClose: () => void;
  onNavigate?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const ActiveStructureCard = ({
  structure,
  onClose,
  onNavigate,
  onReportProblem,
  onReportLostObject,
}: ActiveStructureCardProps) => {
  const { data: campuses } = useCampuses();
  const { data: categories } = useCategories();

  if (!structure) return null;

  const campus = campuses?.find((c) => c.id === structure.campusId);
  const category = categories?.find((c) => c.id === structure.categoryId);

  return (
    <div className="w-full h-full">
      <StructureDetailCard
        title={structure.name}
        subtitle={campus?.name || 'UCT Campus'}
        categoryName={category?.name}
        categoryIcon={category?.icon}
        categoryDescription={category?.description ?? undefined}
        withUctBorder={false}
        onClose={onClose}
        onNavigate={onNavigate}
        onReportProblem={onReportProblem}
        onReportLostObject={onReportLostObject}
      />
    </div>
  );
};
