import type { StructureDto } from '../../dtos/campus/StructureDto';
import { useCampuses } from '../../hooks/useCampus';
import { StructureDetailCard } from './StructureDetailCard';

interface ActiveStructureCardProps {
  structure: StructureDto | null;
  onClose: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const ActiveStructureCard = ({
  structure,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
  onReportLostObject,
}: ActiveStructureCardProps) => {
  const { data: campuses } = useCampuses();

  if (!structure) return null;

  const campus = campuses?.find((c) => c.id === structure.campusId);

  return (
    <div className="w-full h-full">
      <StructureDetailCard
        title={structure.name}
        subtitle={campus?.name || 'UCT Campus'}
        withUctBorder={false}
        onClose={onClose}
        onNavigate={onNavigate}
        onView360={onView360}
        onReportProblem={onReportProblem}
        onReportLostObject={onReportLostObject}
      />
    </div>
  );
};
