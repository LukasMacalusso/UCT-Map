import { BaseDetailCard } from './BaseDetailCard';
import { Tag } from '../../components/ui/Tag';
import { ScheduleCard } from './ScheduleCard';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import DoorIcon from '../../assets/svg/icons/icon_door.svg?react';
import type { RoomData } from '../../interfaces/RoomData';

export interface BuildingDetailCardProps {
  title?: string;
  subtitle?: string;
  images?: string[];
  schedule?: string;
  floors?: string;
  services?: string[];
  rooms?: RoomData[];
  roomsLoading?: boolean;
  withUctBorder?: boolean;
  onClose?: () => void;
  onNavigate?: () => void;
  onView360?: () => void;
  onReportProblem?: () => void;
  onReportLostObject?: () => void;
}

export const BuildingDetailCard = ({
  title = '',
  subtitle = '',
  images = [],
  schedule = '',
  services = [],
  rooms = [],
  roomsLoading = false,
  withUctBorder = true,
  onClose,
  onNavigate,
  onView360,
  onReportProblem,
  onReportLostObject,
}: BuildingDetailCardProps) => {
  const floorNumbers = [...new Set(rooms.map((room) => room.floor))].sort((a, b) => a - b);

  return (
    <BaseDetailCard
      icon={<BuildingIcon className="w-8 h-8 text-gray-800" />}
      title={title}
      subtitle={subtitle}
      images={images}
      withUctBorder={withUctBorder}
      onClose={onClose}
      onNavigate={onNavigate}
      onView360={onView360}
      onReportProblem={onReportProblem}
      onReportLostObject={onReportLostObject}
    >
      <ScheduleCard schedule={schedule} />

      {services.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {services.map((srv, idx) => (
            <Tag key={idx} label={srv} color="blue" className="text-xs py-1.5 px-3.5" />
          ))}
        </div>
      )}

      <div className="flex-1 min-h-0 rounded-2xl bg-page-gray-light px-2 py-1 overflow-y-auto">
        {roomsLoading ? (
          <p className="px-2 py-3 text-sm font-semibold text-gray-500">Cargando salas...</p>
        ) : rooms.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center gap-2 px-4 py-6 text-center">
            <DoorIcon className="w-9 h-9 text-gray-400" />
            <p className="text-sm font-bold text-gray-500">Este edificio no tiene salas registradas</p>
          </div>
        ) : (
          floorNumbers.map((floor) => (
            <div key={floor}>
              <h3 className="sticky top-0 z-10 bg-page-gray-light px-2 py-1 text-[0.7rem] font-black uppercase tracking-widest text-gray-500">
                Piso {floor}
              </h3>

              <ul>
                {rooms
                  .filter((room) => room.floor === floor)
                  .map((room, index) => (
                    <li
                      key={`${room.name}-${index}`}
                      className="flex items-center gap-2 border-b border-gray-300/70 pl-5 pr-2 py-1 last:border-b-0"
                    >
                      <span className="min-w-0 flex-1 truncate text-sm font-bold text-gray-800">
                        {room.name}
                      </span>

                      {room.code && (
                        <span className="shrink-0 text-xs font-bold text-gray-500 tabular-nums">
                          {room.code}
                        </span>
                      )}

                      {room.capacity != null && room.capacity !== '' && (
                        <span className="shrink-0 text-xs font-bold text-gray-700 tabular-nums">
                          [{room.capacity}]
                        </span>
                      )}
                    </li>
                  ))}
              </ul>
            </div>
          ))
        )}
      </div>
    </BaseDetailCard>
  );
};
