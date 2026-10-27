import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';
import { ImageGallery } from '../../components/media/ImageGallery';
import { Tag } from '../../components/ui/Tag';
import { RoomInfoCard } from './RoomInfoCard';
import { ScheduleCard } from './ScheduleCard';
import { BuildingStatCard } from './BuildingStatCard';
import { Button } from '../../components/ui/Button';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import WarningIcon from '../../assets/svg/icons/icon_warning.svg?react';
import NavigationIcon from '../../assets/svg/icons/icon_navigation.svg?react';
import Rotate360Icon from '../../assets/svg/icons/icon_repeat.svg?react';
import LocationIcon from '../../assets/svg/icons/icon_location.svg?react';
import FloorsIcon from '../../assets/svg/icons/icon_floors.svg?react';
import DoorIcon from '../../assets/svg/icons/icon_door.svg?react';

import type { RoomData } from '../../interfaces/RoomData';

export interface BuildingMoreInfoCoordinates {
  latitude: number;
  longitude: number;
}

export interface BuildingMoreInfoCardProps {
  title?: string;
  subtitle?: string;
  images?: string[];
  description?: string;
  schedule?: string;
  floors?: string;
  campus?: string;
  services?: string[];
  rooms?: RoomData[];
  coordinates?: BuildingMoreInfoCoordinates;
  onClose?: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
}

export const BuildingMoreInfoCard = ({
  title = '',
  subtitle = '',
  images = [],
  description = '',
  schedule = '',
  floors = '',
  campus = '',
  services = [],
  rooms = [],
  coordinates,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
}: BuildingMoreInfoCardProps) => {
  return (
    <Panel
      withUctBorder
      color="white"
      size="auto"
      outerClassName="shadow-2xl max-h-[88vh] w-[calc(100vw-2rem)] max-w-4xl"
      innerClassName="p-6 flex flex-col gap-5 max-h-[86vh] overflow-y-auto"
    >
      <div className="flex items-start justify-between gap-2">
        <div className="flex items-center gap-3">
          <BuildingIcon className="w-9 h-9 text-gray-800" />
          <div className="flex flex-col">
            <h2 className="text-2xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
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
        className="w-full h-52 rounded-2xl overflow-hidden"
        images={images}
      />

      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
        {floors && (
          <BuildingStatCard
            icon={<FloorsIcon className="w-5 h-5 text-gray-700" />}
            label="Pisos"
            value={floors}
          />
        )}
        {campus && (
          <BuildingStatCard
            icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
            label="Campus"
            value={campus}
          />
        )}
        <BuildingStatCard
          icon={<DoorIcon className="w-5 h-5 text-gray-700" />}
          label="Salas registradas"
          value={String(rooms.length)}
        />
      </div>

      {description && (
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-bold text-gray-600 uppercase tracking-wider">
            SOBRE ESTE EDIFICIO
          </span>
          <p className="text-sm text-gray-700 leading-relaxed">{description}</p>
        </div>
      )}

      <ScheduleCard schedule={schedule || 'Sin horario registrado'} />

      <div className="flex flex-col gap-1.5">
        <span className="text-xs font-bold text-gray-600 uppercase tracking-wider">
          SERVICIOS
        </span>
        {services.length > 0 ? (
          <div className="flex flex-wrap gap-2">
            {services.map((srv, idx) => (
              <Tag key={idx} label={srv} color="blue" className="text-xs py-1.5 px-3.5" />
            ))}
          </div>
        ) : (
          <p className="text-sm text-gray-500">Sin servicios registrados.</p>
        )}
      </div>

      <div className="flex flex-col gap-2">
        <span className="text-xs font-bold text-gray-600 uppercase tracking-wider">
          SALAS
        </span>
        {rooms.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-64 overflow-y-auto pr-1">
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
        ) : (
          <p className="text-sm text-gray-500">Sin salas registradas.</p>
        )}
      </div>

      {coordinates && (
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-bold text-gray-600 uppercase tracking-wider">
            UBICACIÓN
          </span>
          <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
            <LocationIcon className="w-5 h-5 text-gray-700" />
            <span>
              {coordinates.latitude.toFixed(5)}, {coordinates.longitude.toFixed(5)}
            </span>
          </div>
        </div>
      )}

      <button
        type="button"
        onClick={onReportProblem}
        className="flex items-center gap-3 py-2 text-gray-800 hover:text-red-600 transition-colors font-bold text-sm text-left group"
      >
        <WarningIcon className="w-6 h-6 text-gray-800" />
        <span className="underline group-hover:no-underline">Reportar un problema aquí</span>
      </button>

      <div className="border-t border-gray-200 pt-4 flex flex-col gap-2.5">
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
            variant="outline"
            onClick={onClose}
            className="flex-1 font-black text-base flex items-center justify-center gap-2 py-3 tracking-wider uppercase rounded-xl"
          >
            <span>Cerrar</span>
          </Button>
        </div>
      </div>
    </Panel>
  );
};
