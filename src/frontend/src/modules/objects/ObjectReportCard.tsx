import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { UserActionInfo } from '../../components/ui/UserActionInfo';
import { IconText } from '../../components/ui/IconText';
import { Tag } from '../../components/ui/Tag';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';
import TicketIcon from '../../assets/svg/icons/icon_category.svg?react';


import type { ObjectReportAction } from '../../interfaces/ObjectReportAction';
export interface ObjectReportCardProps {
  title: string;
  status: string;
  statusColor?: 'blue' | 'green' | 'yellow' | 'red' | 'gray' | 'white';
  photoUrl?: string;
  building: string;
  code?: string;
  actions: ObjectReportAction[];
  compact?: boolean;
  className?: string;
}

export const ObjectReportCard = ({
  title,
  status,
  statusColor = 'blue',
  photoUrl,
  building,
  code,
  actions,
  compact = false,
  className = ''
}: ObjectReportCardProps) => {
  return (
    <Panel color="white" outerClassName={`w-full ${compact ? 'max-w-full' : 'max-w-3xl'} ${className}`} innerClassName={`${compact ? 'p-4 gap-4' : 'p-6 gap-6'} flex flex-row items-start`}>
      {/* Object Image */}
      <PhotoFrame src={photoUrl} className={`${compact ? 'w-24 h-24 rounded-xl' : 'w-44 h-44 rounded-2xl'} flex-shrink-0 shadow-sm`} />

      {/* Right container */}
      <div className="flex flex-col flex-1 min-w-0 gap-2">
        {/* Title and state */}
        <div className="flex justify-between items-center mb-1">
          <h2 className={`${compact ? 'text-lg' : 'text-2xl'} font-bold text-gray-800 uppercase tracking-wide leading-tight line-clamp-2 mr-2`}>{title}</h2>
          <Tag label={status} color={statusColor} className={compact ? '!text-xs !px-2.5 !py-0.5' : '!text-sm !px-3.5 !py-1 font-semibold flex-shrink-0'} />
        </div>

        {/* User actions */}
        {!compact && (
          <div className="flex flex-col gap-1.5 my-1">
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

        {/* Code and ubication */}
        <div className={`flex flex-col gap-2 ${compact ? 'mt-1' : 'mt-2'}`}>
          <IconText icon={<MapPinIcon className={compact ? 'w-4 h-4' : 'w-5 h-5'} />} text={building} className={compact ? '!text-xs' : '!text-sm'} />
          {code && (
            <IconText icon={<TicketIcon className={compact ? 'w-4 h-4' : 'w-5 h-5'} />} text={code} className={compact ? '!text-xs' : '!text-sm'} />
          )}
        </div>
      </div>
    </Panel>
  );
};
