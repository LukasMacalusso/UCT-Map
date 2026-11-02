import { Panel } from '../../components/layout/Panel';
import { PhotoFrame } from '../../components/media/PhotoFrame';
import { Button } from '../../components/ui/Button';
import { IconText } from '../../components/ui/IconText';
import EyeIcon from '../../assets/svg/icons/icon_eye.svg?react';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import ClockIcon from '../../assets/svg/icons/icon_clock.svg?react';

export interface ContactCardProps {
  name: string;
  role: string;
  department?: string;
  email?: string;
  office?: string;
  scheduleSummary?: string;
  photoUrl?: string;
  onInfoClick?: () => void;
  className?: string;
}

export const ContactCard = ({
  name,
  role,
  department,
  email,
  office,
  scheduleSummary,
  photoUrl,
  onInfoClick,
  className = '',
}: ContactCardProps) => {
  return (
    <Panel
      color="white"
      outerClassName={`w-full max-w-3xl ${className}`}
      innerClassName="p-6 flex flex-row items-stretch gap-6"
    >
      {/* Photo */}
      <PhotoFrame
        src={photoUrl}
        className="w-40 h-40 sm:w-44 sm:h-44 rounded-2xl flex-shrink-0 shadow-sm self-center"
      />

      {/* Details */}
      <div className="flex flex-col flex-1 min-w-0 justify-between gap-3">
        <div className="flex flex-col min-w-0 gap-1">
          <h3 className="text-xl font-bold text-gray-800 uppercase tracking-wide leading-tight break-words">
            {name}
          </h3>

          <p className="text-sm font-bold text-page-blue uppercase tracking-wide leading-snug line-clamp-1">
            {role}
          </p>
          {department && (
            <p className="text-sm text-gray-600 leading-snug line-clamp-1">
              {department}
            </p>
          )}

          {(email || office || scheduleSummary) && (
            <div className="flex flex-col gap-1.5 mt-1.5 min-w-0">
              {email && (
                <IconText
                  icon={<MailIcon className="w-5 h-5 flex-shrink-0" />}
                  text={email}
                  className="!text-sm font-medium"
                />
              )}
              {office && (
                <IconText
                  icon={<BuildingIcon className="w-5 h-5 flex-shrink-0" />}
                  text={office}
                  className="!text-sm font-medium"
                />
              )}
              {scheduleSummary && (
                <IconText
                  icon={<ClockIcon className="w-5 h-5 flex-shrink-0" />}
                  text={scheduleSummary}
                  className="!text-sm font-medium"
                />
              )}
            </div>
          )}
        </div>

        {/* Button */}
        <div className="flex justify-end pt-1">
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
      </div>
    </Panel>
  );
};
