import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { UserActionInfo } from '../../components/ui/UserActionInfo';
import { IconText } from '../../components/ui/IconText';
import { Tag } from '../../components/ui/Tag';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';


export interface IncidentCardProps {
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
}

export const IncidentCard = ({
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
  className = ''
}: IncidentCardProps) => {
  return (
    <Panel color="white" outerClassName={`w-full ${compact ? 'max-w-full' : 'max-w-2xl'} ${className}`} innerClassName={`${compact ? 'p-3 gap-2.5' : 'p-5 gap-3.5'} flex flex-col`}>
      {/* Ubication and state */}
      <div className="flex justify-between items-center mb-1">
        <IconText icon={<MapPinIcon className={compact ? 'w-4 h-4' : 'w-5 h-5'} />} text={location} className={compact ? '!text-xs font-medium' : '!text-sm font-medium'} />
        <Tag label={status} color={statusColor} className={`${compact ? '!text-xs !px-2.5 !py-0.5' : '!text-xs !px-3 !py-1 font-semibold'} uppercase`} />
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
      <p className={`${compact ? 'text-xs' : 'text-sm'} text-gray-600 leading-relaxed mt-1 line-clamp-2`}>
        "{description}"
      </p>
    </Panel>
  );
};
