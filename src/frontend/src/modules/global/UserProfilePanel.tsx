import { useState, useMemo } from 'react';
import { Panel } from '../../components/layout/Panel';
import { Avatar } from '../../components/media/Avatar';
import { IconText } from '../../components/ui/IconText';
import { CloseButton } from '../../components/ui/ExitButton';
import { Button } from '../../components/ui/Button';
import { Tag } from '../../components/ui/Tag';
import { ROLE_STYLES, Role } from '../../constants/role';
import type { PageColor } from '../../constants/colors';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import StudyIcon from '../../assets/svg/icons/icon_study.svg?react';
import CalendarIcon from '../../assets/svg/icons/icon_calendar.svg?react';
import ClockIcon from '../../assets/svg/icons/icon_clock.svg?react';
import BuildingIcon from '../../assets/svg/icons/icon_building.svg?react';
import UserIcon from '../../assets/svg/icons/icon_user.svg?react';
import { ObjectReportCard, type ObjectReportCardProps } from '../objects/ObjectReportCard';
import { IncidentCard, type IncidentCardProps } from '../incidents/IncidentCard';
import { EmptyState } from '../../components/ui/EmptyState';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export interface UserProfileMeetingItem {
  id: string;
  teacherName: string;
  teacherEmail?: string;
  location: string;
  dateLabel: string;
  timeLabel: string;
  statusLabel: string;
  statusColor?: PageColor;
  canCancel?: boolean;
}

export interface UserProfilePanelProps {
  name: string;
  admissionYear?: string;
  career?: string;
  email: string;
  photoUrl?: string;
  role?: Role;
  objectReports?: ObjectReportCardProps[];
  incidentReports?: IncidentCardProps[];
  requestedMeetings?: UserProfileMeetingItem[];
  isLoading?: boolean;
  isOwnProfile?: boolean;
  showAllTabs?: boolean;
  onCancelMeeting?: (meetingId: string) => void;
  isCancellingMeeting?: boolean;
  onClose?: () => void;
  onLogout?: () => void;
}

type ProfileTab = 'objects' | 'incidents' | 'meetings';

const getRoleConfig = (role?: Role): { label: string; color: PageColor } => {
  if (!role) return { label: 'ESTUDIANTE', color: 'blue' };
  return ROLE_STYLES[role];
};

export const UserProfilePanel = ({
  name,
  admissionYear,
  career,
  email,
  photoUrl,
  role,
  objectReports = [],
  incidentReports = [],
  requestedMeetings = [],
  isLoading = false,
  isOwnProfile = true,
  showAllTabs = false,
  onCancelMeeting,
  isCancellingMeeting = false,
  onClose,
  onLogout,
}: UserProfilePanelProps) => {
  const canViewObjects = Boolean(
    showAllTabs ||
    role === Role.Admin ||
    role === Role.ObjectsOfficer
  );

  const availableTabs = useMemo<{ id: ProfileTab; label: string }[]>(() => {
    const tabs: { id: ProfileTab; label: string }[] = [];
    if (canViewObjects) {
      tabs.push({ id: 'objects', label: `Objetos (${objectReports.length})` });
    }
    tabs.push({ id: 'incidents', label: `Incidencias (${incidentReports.length})` });
    tabs.push({ id: 'meetings', label: `Reuniones (${requestedMeetings.length})` });
    return tabs;
  }, [canViewObjects, objectReports.length, incidentReports.length, requestedMeetings.length]);

  const [activeTab, setActiveTab] = useState<ProfileTab>(() =>
    canViewObjects ? 'objects' : 'incidents'
  );

  const effectiveTab = availableTabs.some((t) => t.id === activeTab)
    ? activeTab
    : (availableTabs[0]?.id ?? 'incidents');

  const activeIndex = Math.max(
    0,
    availableTabs.findIndex((t) => t.id === effectiveTab)
  );

  if (isLoading) {
    return <LoadingSpinner size="xl" text="Cargando perfil..." className="py-12" />;
  }

  const roleConfig = getRoleConfig(role);

  return (
    <Panel color="white" withUctBorder={true} size="xl" outerClassName="!w-[64rem] max-w-[95vw] !h-[44rem] max-h-[90vh]" innerClassName="p-6 lg:p-8 flex flex-col relative h-full overflow-hidden">
      {/* Close button positioned top-right */}
      <div className="absolute top-5 right-5 z-10">
        <CloseButton onClick={onClose} variant="ghost" size="md" />
      </div>

      <div className="flex flex-col lg:flex-row gap-8 mt-4 lg:mt-0 flex-1 min-h-0 overflow-hidden">
        
        {/* Left Section: Profile Info */}
        <div className="flex flex-col items-center w-full lg:w-1/3 flex-shrink-0 lg:pt-2 overflow-y-auto pb-2">
          <h3 className="text-xl font-black text-gray-700 uppercase tracking-wider mb-5 w-full text-center">Información de Cuenta</h3>
          
          <Avatar src={photoUrl} size="xl" className="mb-4 shadow-lg" />
          
          <h2 className="text-2xl font-black text-gray-800 uppercase text-center leading-tight mb-2">{name}</h2>
          
          <Tag
            label={roleConfig.label}
            color={roleConfig.color}
            className="mb-5 text-xs px-3.5 py-1 shadow-sm font-bold tracking-wide"
          />
          
          <div className="flex flex-col gap-3.5 w-full px-2 mb-6">
            {admissionYear && (
              <IconText icon={<CalendarIcon className="w-5 h-5 flex-shrink-0" />} text={`Ingreso: ${admissionYear}`} className="text-sm font-medium" />
            )}
            {career && (
              <IconText icon={<StudyIcon className="w-5 h-5 flex-shrink-0" />} text={career} className="text-sm font-medium leading-snug" />
            )}
            <IconText icon={<MailIcon className="w-5 h-5 flex-shrink-0" />} text={email} className="text-sm font-medium break-all" />
          </div>

          {onLogout && (
            <Button variant="outline" color="red" size="md" className="w-max px-6 font-bold tracking-wide mt-auto" onClick={onLogout}>
              CERRAR SESIÓN
            </Button>
          )}
        </div>

        {/* Vertical Divider */}
        <div className="hidden lg:block w-px bg-gray-200"></div>
        <hr className="block lg:hidden border-t-2 border-gray-200 w-full" />

        {/* Right Section: Reports & Meetings */}
        <div className="flex flex-col flex-1 w-full min-w-0 lg:pt-2 h-full min-h-0">
          <h3 className="text-xl font-black text-gray-700 uppercase tracking-wider mb-2 px-1">{isOwnProfile ? 'Tus Contribuciones' : 'Contribuciones'}</h3>
          
          <div className="relative flex border-b-2 border-gray-200 mt-1 flex-shrink-0">
            {availableTabs.map((tab) => {
              const isSelected = effectiveTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  className={`w-40 text-sm sm:text-base font-bold py-2.5 transition-colors duration-200 z-10 cursor-pointer text-center
                    ${isSelected ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}
                  `}
                  onClick={() => setActiveTab(tab.id)}
                >
                  {tab.label}
                </button>
              );
            })}

            {/* Animated Sliding Bar */}
            <div
              className="absolute bottom-[-2px] left-0 h-[4px] w-40 bg-page-blue rounded-full transition-transform duration-300 ease-out z-0 pointer-events-none"
              style={{ transform: `translateX(${activeIndex * 100}%)` }}
            />
          </div>

          <div className="bg-page-gray-light mt-4 p-4 rounded-2xl overflow-y-auto flex flex-col gap-3 flex-1 min-h-0 shadow-inner">
            <div key={effectiveTab} className="w-full flex flex-col gap-3 animate-tab-fade">
              {effectiveTab === 'objects' && canViewObjects && (
                objectReports.length > 0 ? objectReports.map((report, idx) => (
                  <ObjectReportCard key={idx} {...report} compact={true} className="!w-full !max-w-full shadow-sm hover:shadow-md transition-shadow" />
                )) : <EmptyState message="No hay reportes de objetos" />
              )}

              {effectiveTab === 'incidents' && (
                incidentReports.length > 0 ? incidentReports.map((incident, idx) => (
                  <IncidentCard key={idx} {...incident} compact={true} className="!w-full !max-w-full shadow-sm hover:shadow-md transition-shadow" />
                )) : <EmptyState message="No hay incidencias reportadas" />
              )}

              {effectiveTab === 'meetings' && (
                requestedMeetings.length > 0 ? requestedMeetings.map((meeting) => (
                  <Panel
                    key={meeting.id}
                    color="white"
                    outerClassName="!w-full !max-w-full shadow-sm hover:shadow-md transition-shadow"
                    innerClassName="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                  >
                    <div className="flex flex-col gap-1.5 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-bold text-gray-800 text-sm sm:text-base">
                          {meeting.dateLabel}
                        </span>
                        <span className="text-xs sm:text-sm font-semibold text-page-blue flex items-center gap-1">
                          <ClockIcon className="w-3.5 h-3.5" />
                          {meeting.timeLabel}
                        </span>
                      </div>

                      <div className="flex flex-wrap items-center gap-4 text-xs text-gray-600">
                        <IconText
                          icon={<UserIcon className="w-4 h-4 text-gray-700" />}
                          text={
                            meeting.teacherEmail
                              ? `Prof. ${meeting.teacherName} (${meeting.teacherEmail})`
                              : `Prof. ${meeting.teacherName}`
                          }
                          className="!text-xs"
                        />
                        <IconText
                          icon={<BuildingIcon className="w-4 h-4 text-gray-700" />}
                          text={meeting.location}
                          className="!text-xs"
                        />
                      </div>
                    </div>

                    <div className="flex items-center gap-2 flex-shrink-0 self-start sm:self-center">
                      {meeting.canCancel && onCancelMeeting && (
                        <Button
                          size="sm"
                          variant="outline"
                          color="red"
                          className="!w-auto !py-1 !px-3 !text-xs uppercase font-bold"
                          onClick={() => onCancelMeeting(meeting.id)}
                          disabled={isCancellingMeeting}
                        >
                          Cancelar
                        </Button>
                      )}
                      <Tag
                        label={meeting.statusLabel}
                        color={meeting.statusColor ?? 'blue'}
                        className="!text-xs !px-3 !py-1 font-semibold flex-shrink-0"
                      />
                    </div>
                  </Panel>
                )) : <EmptyState message="No hay reuniones solicitadas" />
              )}
            </div>
          </div>
        </div>
      </div>
    </Panel>
  );
};
