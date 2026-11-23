import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { Button } from '../../components/ui/Button';
import { IconText } from '../../components/ui/IconText';
import EyeIcon from '../../assets/svg/icons/icon_eye.svg?react';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import MapPinIcon from '../../assets/svg/icons/icon_location.svg?react';
import ClockIcon from '../../assets/svg/icons/icon_clock.svg?react';

export interface ContactCardProps {
  name: string;
  role?: string;
  department?: string;
  campus?: string;
  office?: string;
  email?: string;
  scheduleSummary?: string;
  photoUrl?: string;
  onInfoClick?: () => void;
  className?: string;
  compact?: boolean;
}

export const ContactCard = ({
  name,
  department,
  campus,
  office,
  email,
  scheduleSummary,
  photoUrl,
  onInfoClick,
  className = '',
  compact = false,
}: ContactCardProps) => {
  return (
    <Panel
      color="white"
      outerClassName={`w-full ${compact ? 'max-w-full' : 'max-w-3xl min-h-[14rem]'} ${className}`}
      innerClassName={`${compact ? 'p-4 gap-4' : 'p-5 gap-5'} flex flex-row items-stretch`}
    >
      {/* Photo */}
      <PhotoFrame
        src={photoUrl}
        className={`${compact ? 'w-24 h-24 rounded-xl' : 'w-44 h-full min-h-[11rem] rounded-2xl'} flex-shrink-0 shadow-sm`}
      />

      {/* Details */}
      <div className="flex flex-col flex-1 min-w-0 justify-between self-stretch">
        <div className="flex flex-col gap-1.5">
          {/* Name */}
          <div className="mb-0.5">
            <h3 className={`${compact ? 'text-base' : 'text-xl'} font-bold text-gray-800 uppercase tracking-wide leading-tight line-clamp-2`}>
              {name}
            </h3>
            {department && (
              <p className="text-xs text-gray-500 font-medium leading-tight line-clamp-1 mt-0.5">
                {department}
              </p>
            )}
          </div>

          {/* Contact Details (campus, office, email, schedule) */}
          <div className="flex flex-col gap-1">
            {campus && (
              <IconText
                icon={<BuildingIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={campus}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
            {office && (
              <IconText
                icon={<MapPinIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={office}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
            {email && (
              <IconText
                icon={<MailIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={email}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
            {scheduleSummary && (
              <IconText
                icon={<ClockIcon className={compact ? 'w-3.5 h-3.5 text-gray-500' : 'w-4 h-4 text-gray-500'} />}
                text={scheduleSummary}
                className={`${compact ? '!text-xs' : '!text-sm'} font-medium text-gray-600`}
              />
            )}
          </div>
        </div>

        {/* Action Button */}
        {onInfoClick && (
          <div className="pt-2 flex justify-end">
            <Button
              variant="solid"
              onClick={onInfoClick}
              className="!w-auto px-6 py-2"
              size="sm"
            >
              <span className="flex items-center justify-center gap-2 text-sm sm:text-base font-bold">
                <EyeIcon className="w-5 h-5" />
                INFO
              </span>
            </Button>
          </div>
        )}
      </div>
    </Panel>
  );
};
