import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';
import { ImageGallery } from '../../components/media/ImageGallery';
import { Tag } from '../../components/ui/Tag';
import { Button } from '../../components/ui/Button';
import { RoleGuard } from '../../router/RoleGuard';
import { Role } from '../../constants/role';
import CubeIcon from '../../assets/svg/icons/icon_category_cube.svg?react';
import WarningIcon from '../../assets/svg/icons/icon_warning.svg?react';
import ObjectsIcon from '../../assets/svg/icons/icon_section_objects.svg?react';
import NavigationIcon from '../../assets/svg/icons/icon_navigation.svg?react';
import MapPinIcon from '../../assets/svg/icons/icon_map_pin.svg?react';

export interface StructureDetailCardProps {
  title?: string;
  subtitle?: string;
  images?: string[];
  categoryName?: string;
  categoryIcon?: string;
  categoryDescription?: string;
  withUctBorder?: boolean;
  onClose?: () => void;
  onNavigate?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const StructureDetailCard = ({
  title = '',
  subtitle = '',
  images = [],
  categoryName,
  categoryDescription,
  withUctBorder = true,
  onClose,
  onNavigate,
  onReportProblem,
  onReportLostObject,
}: StructureDetailCardProps) => {
  return (
    <Panel
      withUctBorder={withUctBorder}
      color="white"
      outerClassName="rounded-3xl w-full min-w-[28.25rem] min-h-full max-h-full"
      innerClassName="p-5 flex flex-col gap-4"
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-3 min-w-0">
          <CubeIcon className="w-8 h-8 text-gray-800 shrink-0" />
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
        className="w-full h-44 rounded-2xl overflow-hidden"
        images={images}
      />

      {categoryName && (
        <div className="flex flex-wrap gap-2">
          <Tag label={categoryName} color="yellow" className="text-xs py-1.5 px-3.5 font-bold" />
        </div>
      )}

      <div className="flex-1 min-h-0 rounded-2xl bg-page-gray-light p-4 overflow-y-auto flex flex-col gap-3">
        {categoryDescription ? (
          <div className="flex flex-col gap-1.5">
            <h3 className="text-[0.7rem] font-black uppercase tracking-widest text-gray-500">
              Descripción
            </h3>
            <p className="text-sm font-semibold text-gray-700 leading-relaxed whitespace-pre-line">
              {categoryDescription}
            </p>
          </div>
        ) : (
          <div className="flex h-full flex-col items-center justify-center gap-2 px-4 py-6 text-center">
            <CubeIcon className="w-9 h-9 text-gray-400" />
            <p className="text-sm font-bold text-gray-500">Estructura registrada en campus universitario</p>
          </div>
        )}

        <div className="mt-auto pt-2 flex items-center gap-2 text-xs font-semibold text-gray-500 border-t border-gray-200/60">
          <MapPinIcon className="w-4 h-4 text-page-blue shrink-0" />
          <span>Punto de interés universitario</span>
        </div>
      </div>

      <div className="flex flex-col gap-1.5 shrink-0">
        <Button
          color="blue"
          variant="solid"
          onClick={onNavigate}
          className="w-full font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
        >
          <NavigationIcon className="w-6 h-6 text-white" />
          <span>LLEGAR</span>
        </Button>

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
