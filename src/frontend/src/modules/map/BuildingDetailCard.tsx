import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';
import { ImageGallery } from '../../components/media/ImageGallery';
import { Tag } from '../../components/ui/Tag';
import { RoomInfoCard } from './RoomInfoCard';
import { ScheduleCard } from './ScheduleCard';
import { Button } from '../../components/ui/Button';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import WarningIcon from '../../assets/svg/icons/icon_warning.svg?react';
import NavigationIcon from '../../assets/svg/icons/icon_navigation.svg?react';
import Rotate360Icon from '../../assets/svg/icons/icon_repeat.svg?react';
import InfoIcon from '../../assets/svg/icons/icon_info.svg?react';

import type { RoomData } from '../../interfaces/RoomData';

export interface BuildingDetailCardProps {
  title?: string;
  subtitle?: string;
  images?: string[];
  schedule?: string;
  floors?: string;
  services?: string[];
  rooms?: RoomData[];
  withUctBorder?: boolean;
  onClose?: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onInfo?: () => void;
  onReportProblem?: () => void;
}

export const BuildingDetailCard = ({
  title = "",
  subtitle = "",
  images = [],
  schedule = "",
  floors = "",
  services = [],
  rooms = [],
  withUctBorder = true,
  onClose,
  onNavigate,
  onView360,
  onInfo,
  onReportProblem,
}: BuildingDetailCardProps) => {
  return (
    <Panel
      withUctBorder={withUctBorder}
      color="white"
      outerClassName="rounded-3xl w-full h-full"
      innerClassName="p-5 flex flex-col gap-4 h-full"
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-3">
          <BuildingIcon className="w-8 h-8 text-gray-800" />
          <div className="flex flex-col">
            <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
              {title}
            </h2>
            <span className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
              {subtitle}{floors ? ` - ${floors}` : ''}
            </span>
          </div>
        </div>
        <CloseButton variant="ghost" size="lg" onClick={onClose} />
      </div>

      <ImageGallery
        className="w-full h-44 rounded-2xl overflow-hidden"
        images={images}
      />

      <ScheduleCard schedule={schedule} />

      <div className="flex flex-col gap-1.5">
        <span className="text-xs font-bold text-gray-600 uppercase tracking-wider">
          SERVICIOS
        </span>
        <div className="flex flex-wrap gap-2">
          {services.map((srv, idx) => (
            <Tag key={idx} label={srv} color="blue" className="text-xs py-1.5 px-3.5" />
          ))}
        </div>
      </div>

      <div className="flex flex-col gap-2 flex-1 min-h-0">
        <span className="text-xs font-bold text-gray-600 uppercase tracking-wider shrink-0">
          SALAS
        </span>
        <div className="flex flex-col gap-2 flex-1 overflow-y-auto pr-1">
          {rooms.map((room, idx) => (
            <RoomInfoCard
              key={idx}
              title={room.title}
              type={room.type}
              capacity={room.capacity}
              className="max-w-none text-sm p-3"
            />
          ))}
        </div>
      </div>

      <button
        type="button"
        onClick={onReportProblem}
        className="flex items-center gap-3 py-2 text-gray-800 hover:text-red-600 transition-colors font-bold text-sm text-left group"
      >
        <WarningIcon className="w-6 h-6 text-gray-800" />
        <span className="underline group-hover:no-underline">Reportar un problema aquí</span>
      </button>

      <div className="border-t border-gray-200 pt-3 flex flex-col gap-2.5">
        <Button
          color="blue"
          variant="solid"
          onClick={onNavigate}
          className="w-full font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
        >
          <NavigationIcon className="w-6 h-6 text-white" />
          <span>LLEGAR</span>
        </Button>

        <div className="flex items-center gap-2.5">
          <Button
            color="blue"
            variant="solid"
            onClick={onView360}
            className="flex-1 font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
          >
            <Rotate360Icon className="w-6 h-6 text-white" />
            <span>360°</span>
          </Button>

          <Button
            color="blue"
            variant="solid"
            onClick={onInfo}
            className="flex-1 font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
          >
            <InfoIcon className="w-6 h-6 text-white" />
            <span>Info</span>
          </Button>
        </div>
      </div>
    </Panel>
  );
};
