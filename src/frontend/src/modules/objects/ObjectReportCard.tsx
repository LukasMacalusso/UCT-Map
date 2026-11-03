import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { UserActionInfo } from '../../components/ui/UserActionInfo';
import { IconText } from '../../components/ui/IconText';
import { Tag } from '../../components/ui/Tag';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import TicketIcon from '../../assets/svg/icons/icon_category.svg?react';
import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';


import type { ObjectReportAction } from '../../interfaces/ObjectReportAction';
export interface ObjectReportCardProps {
  title: string;
  status: string;
  statusColor?: 'blue' | 'green' | 'yellow' | 'red' | 'gray' | 'white';
  photoUrl?: string;
  campus?: string;
  building: string;
  code?: string;
  actions: ObjectReportAction[];
  compact?: boolean;
  className?: string;
  onStatusChangeClick?: () => void;
}

export const ObjectReportCard = ({
  title,
  status,
  statusColor = 'blue',
  photoUrl,
  campus,
  building,
  code,
  actions,
  compact = false,
  className = '',
  onStatusChangeClick,
}: ObjectReportCardProps) => {
  return (
    <Panel
      color="white"
      outerClassName={`w-full ${compact ? 'max-w-full' : 'max-w-3xl min-h-[14rem]'} ${className}`}
      innerClassName={`${compact ? 'p-4 gap-4' : 'p-5 gap-5'} flex flex-row items-stretch`}
    >
      {/* Object Image */}
      <PhotoFrame
        src={photoUrl}
        className={`${compact ? 'w-24 h-24 rounded-xl' : 'w-44 h-full min-h-[11rem] rounded-2xl'} flex-shrink-0 shadow-sm`}
      />

      {/* Right container */}
      <div className="flex flex-col flex-1 min-w-0 justify-between self-stretch">
        <div className="flex flex-col gap-1.5">
          {/* Title and state */}
          <div className="flex justify-between items-start mb-0.5">
            <h2 className={`${compact ? 'text-base' : 'text-xl'} font-bold text-gray-800 uppercase tracking-wide leading-tight line-clamp-2 mr-2`}>{title}</h2>
            <Tag label={status} color={statusColor} className={`${compact ? '!text-xs !px-2.5 !py-0.5' : '!text-xs !px-3 !py-1 font-semibold'} uppercase flex-shrink-0`} />
          </div>

          {/* User actions */}
          {!compact && (
            <div className="flex flex-col gap-1 my-0.5">
              {actions.map((action, idx) => (
                <UserActionInfo
                  key={idx}
                  title={action.title}
                  subtitle={action.subtitle}
                  avatarSrc={action.avatarSrc}
                  size="sm"
                  className="!p-0 !bg-transparent"
                />
              ))}
            </div>
          )}

          {/* Location: Campus & Building */}
          <div className="flex flex-col gap-1">
            {campus && (
              <IconText
                icon={<BuildingIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={campus}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
            <IconText
              icon={<MapPinIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
              text={building}
              className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
            />
            {code && (
              <IconText
                icon={<TicketIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={code}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
          </div>
        </div>

        {/* Bottom Action: Change Status */}
        {onStatusChangeClick && (
          <div className="pt-2 flex justify-end">
            <button
              type="button"
              onClick={onStatusChangeClick}
              className="flex items-center gap-1.5 px-3 py-1 text-xs font-bold rounded-xl border border-gray-200 bg-gray-50 text-gray-700 hover:text-page-blue hover:border-page-blue/50 hover:bg-blue-50/70 transition-all cursor-pointer shadow-2xs active:scale-95"
              title="Cambiar estado del objeto"
            >
              <PencilIcon className="w-3.5 h-3.5" />
              <span>Cambiar estado</span>
            </button>
          </div>
        )}
      </div>
    </Panel>
  );
};
