import type React from 'react';
import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';
import { ImageGallery } from '../../components/media/ImageGallery';
import { Button } from '../../components/ui/Button';
import { RoleGuard } from '../../router/RoleGuard';
import { Role } from '../../constants/role';
import NavigationIcon from '../../assets/svg/icons/icon_navigation.svg?react';
import Rotate360Icon from '../../assets/svg/icons/icon_repeat.svg?react';
import WarningIcon from '../../assets/svg/icons/icon_warning.svg?react';
import ObjectsIcon from '../../assets/svg/icons/icon_section_objects.svg?react';

export interface BaseDetailCardProps {
  icon?: React.ReactNode;
  title?: string;
  subtitle?: string;
  images?: string[];
  withUctBorder?: boolean;
  children?: React.ReactNode;
  onClose?: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const BaseDetailCard = ({
  icon,
  title = '',
  subtitle = '',
  images = [],
  withUctBorder = false,
  children,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
  onReportLostObject,
}: BaseDetailCardProps) => {
  return (
    <Panel
      withUctBorder={withUctBorder}
      color="white"
      outerClassName="rounded-3xl w-full min-w-[28.25rem] min-h-full max-h-full"
      innerClassName="p-5 flex flex-col justify-between h-full gap-4"
    >
      <div className="flex flex-col gap-4 min-h-0 flex-1">
        <div className="flex items-start justify-between gap-2 shrink-0">
          <div className="flex items-center gap-3 min-w-0">
            {icon && <div className="shrink-0">{icon}</div>}
            <div className="flex flex-col min-w-0">
              <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight truncate">
                {title}
              </h2>
              <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide truncate">
                {subtitle}
              </span>
            </div>
          </div>
          <CloseButton variant="ghost" size="lg" onClick={onClose} />
        </div>

        <ImageGallery
          className="w-full h-44 rounded-2xl overflow-hidden shrink-0"
          images={images}
        />

        {children}
      </div>

      <div className="flex flex-col gap-1.5 shrink-0 mt-auto pt-2">
        <div className="flex items-center gap-2.5">
          <Button
            color="blue"
            variant="solid"
            onClick={onNavigate}
            className="flex-1 font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
          >
            <NavigationIcon className="w-6 h-6 text-white" />
            <span>LLEGAR</span>
          </Button>

          <Button
            color="blue"
            variant="solid"
            onClick={onView360}
            className="flex-1 font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
          >
            <Rotate360Icon className="w-6 h-6 text-white" />
            <span>360°</span>
          </Button>
        </div>

        {onReportProblem && (
          <RoleGuard allowedRoles={[Role.ComplaintsOfficer, Role.Admin]}>
            <button
              type="button"
              onClick={onReportProblem}
              className="self-center flex items-center gap-3 py-1 text-gray-800 hover:text-red-600 transition-colors font-bold text-sm group"
            >
              <WarningIcon className="w-6 h-6 text-gray-800" />
              <span className="underline group-hover:no-underline">Reportar un problema aquí</span>
            </button>
          </RoleGuard>
        )}

        {onReportLostObject && (
          <RoleGuard allowedRoles={[Role.ObjectsOfficer, Role.Admin]}>
            <button
              type="button"
              onClick={onReportLostObject}
              className="self-center flex items-center gap-3 py-1 text-gray-800 hover:text-page-blue transition-colors font-bold text-sm group"
            >
              <ObjectsIcon className="w-6 h-6 text-gray-800" />
              <span className="underline group-hover:no-underline">Reportar objeto perdido aquí</span>
            </button>
          </RoleGuard>
        )}
      </div>
    </Panel>
  );
};
