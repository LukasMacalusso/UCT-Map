import { BaseDetailCard } from './BaseDetailCard';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';

export interface StructureDetailCardProps {
  title?: string;
  subtitle?: string;
  images?: string[];
  withUctBorder?: boolean;
  onClose?: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const StructureDetailCard = ({
  title = '',
  subtitle = '',
  images = [],
  withUctBorder = true,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
  onReportLostObject,
}: StructureDetailCardProps) => {
  return (
    <BaseDetailCard
      icon={<CubeIcon className="w-8 h-8 text-gray-800 shrink-0" />}
      title={title}
      subtitle={subtitle}
      images={images}
      withUctBorder={withUctBorder}
      onClose={onClose}
      onNavigate={onNavigate}
      onView360={onView360}
      onReportProblem={onReportProblem}
      onReportLostObject={onReportLostObject}
    />
  );
};
