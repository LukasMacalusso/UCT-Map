import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { UserActionInfo } from '../../components/ui/UserActionInfo';
import { IconText } from '../../components/ui/IconText';
import { Tag } from '../../components/ui/Tag';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import PencilIcon from '../../assets/svg/icons/icon_pencil.svg?react';


export interface IncidentCardProps {
  campus?: string;
  location: string;
  status: string;
  statusColor?: 'blue' | 'green' | 'yellow' | 'red' | 'gray' | 'white';
  photoUrl?: string;
  title: string;
  reporterName: string;
  reportTime: string;
  reporterAvatar?: string;
  description: string;
  compact?: boolean;
  className?: string;
  onStatusChangeClick?: () => void;
}

export const IncidentCard = ({
  campus,
  location,
  status,
  statusColor = 'red',
  photoUrl,
  title,
  reporterName,
  reportTime,
  reporterAvatar,
  description,
  compact = false,
  className = '',
  onStatusChangeClick,
}: IncidentCardProps) => {
  return (
    <Panel
      color="white"
      outerClassName={`w-full ${compact ? '!w-full !max-w-full' : 'max-w-2xl min-h-[35rem]'} flex flex-col justify-between ${className}`}
      innerClassName={`${compact ? 'p-3 gap-2.5' : 'p-5 gap-3.5'} flex flex-col h-full justify-between flex-1`}
    >
      <div className="flex flex-col gap-2.5">
        {/* Location (Campus & Building) and state */}
        <div className="flex justify-between items-start gap-2 mb-1">
          <div className="flex flex-col gap-1 min-w-0">
            {campus && (
              <IconText
                icon={<BuildingIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={campus}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
            <IconText
              icon={<MapPinIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
              text={location}
              className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
            />
          </div>
          <Tag label={status} color={statusColor} className={`${compact ? '!text-xs !px-2.5 !py-0.5' : '!text-xs !px-3 !py-1 font-semibold'} uppercase flex-shrink-0`} />
        </div>

        {/* Incident image */}
        <PhotoFrame src={photoUrl} className={`w-full ${compact ? 'h-28 rounded-xl' : 'h-52 rounded-2xl'} object-cover mb-1 shadow-sm`} />

        {/* Incident name */}
        <h2 className={`${compact ? 'text-base' : 'text-xl'} font-bold text-gray-800 uppercase tracking-wide leading-tight line-clamp-2`}>
          {title}
        </h2>

        {/* Report Information */}
        {!compact && (
          <UserActionInfo
            title={`Reportado por ${reporterName}`}
            subtitle={reportTime}
            avatarSrc={reporterAvatar}
            size="sm"
            className="!p-0 !bg-transparent"
          />
        )}

        {/* Description */}
        <p className={`${compact ? 'text-xs' : 'text-sm'} text-gray-600 leading-relaxed line-clamp-3 break-words`}>
          "{description}"
        </p>
      </div>

      {/* Bottom Action: Change Status */}
      {onStatusChangeClick && (
        <div className="mt-3 pt-2.5 border-t border-gray-100 flex justify-end">
          <button
            type="button"
            onClick={onStatusChangeClick}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-xl border border-gray-200 bg-gray-50 text-gray-700 hover:text-page-blue hover:border-page-blue/50 hover:bg-blue-50/70 transition-all cursor-pointer shadow-2xs active:scale-95"
            title="Cambiar estado del reporte"
          >
            <PencilIcon className="w-3.5 h-3.5" />
            <span>Cambiar estado</span>
          </button>
        </div>
      )}
    </Panel>
  );
};
