import { useState } from 'react';
import { Panel } from '../../components/layout/Panel';
import { Avatar } from '../../components/media/Avatar';
import { IconText } from '../../components/ui/IconText';
import { CloseButton } from '../../components/ui/ExitButton';
import { Button } from '../../components/ui/Button';
import { Tag } from '../../components/ui/Tag';
import { ROLE_STYLES, type Role } from '../../constants/role';
import type { PageColor } from '../../constants/colors';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import StudyIcon from '../../assets/svg/icons/icon_study.svg?react';
import CalendarIcon from '../../assets/svg/icons/icon_calendar.svg?react';
import { ObjectReportCard } from '../objects/ObjectReportCard';
import { IncidentCard } from '../incidents/IncidentCard';
import { EmptyState } from '../../components/ui/EmptyState';
import { LoadingSpinner } from '../../components/ui/LoadingSpinner';

export interface UserProfilePanelProps {
  name: string;
  admissionYear?: string;
  career?: string;
  email: string;
  photoUrl?: string;
  role?: Role;
  objectReports?: any[];
  incidentReports?: any[];
  isLoading?: boolean;
  isOwnProfile?: boolean;
  onClose?: () => void;
  onLogout?: () => void;
}

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
  isLoading = false,
  isOwnProfile = true,
  onClose,
  onLogout,
}: UserProfilePanelProps) => {
  const [activeTab, setActiveTab] = useState<'objects' | 'incidents'>('objects');
  const [prevTab, setPrevTab] = useState<'objects' | 'incidents'>('objects');

  if (isLoading) {
    return <LoadingSpinner size="xl" text="Cargando perfil..." className="py-12" />;
  }

  const roleConfig = getRoleConfig(role);

  const handleTabChange = (tab: 'objects' | 'incidents') => {
    if (tab !== activeTab) {
      setPrevTab(activeTab);
      setActiveTab(tab);
    }
  };

  return (
    <Panel color="white" withUctBorder={true} size="lg" innerClassName="p-6 lg:p-8 flex flex-col relative max-h-[85vh] overflow-hidden">
      {/* Close button positioned top-right */}
      <div className="absolute top-5 right-5">
        <CloseButton onClick={onClose} variant="ghost" size="md" />
      </div>

      <div className="flex flex-col lg:flex-row gap-8 mt-4 lg:mt-0 flex-1 overflow-hidden">
        
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
            <Button variant="outline" color="red" size="md" className="w-max px-6 font-bold tracking-wide" onClick={onLogout}>
              CERRAR SESIÓN
            </Button>
          )}
        </div>

        {/* Vertical Divider */}
        <div className="hidden lg:block w-px bg-gray-200"></div>
        <hr className="block lg:hidden border-t-2 border-gray-200 w-full" />

        {/* Right Section: Reports */}
        <div className="flex flex-col flex-1 w-full min-w-0 lg:pt-2 h-full">
          <h3 className="text-xl font-black text-gray-700 uppercase tracking-wider mb-2 px-1">{isOwnProfile ? 'Tus Contribuciones' : 'Contribuciones'}</h3>
          
          <div className="relative flex border-b-2 border-gray-200 mt-1 flex-shrink-0">
            <button 
              className={`w-40 text-base font-bold py-2.5 transition-colors z-10
                ${activeTab === 'objects' ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}
              `}
              onClick={() => handleTabChange('objects')}
            >
              Objetos ({objectReports.length})
            </button>
            <button 
              className={`w-40 text-base font-bold py-2.5 transition-colors z-10
                ${activeTab === 'incidents' ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}
              `}
              onClick={() => handleTabChange('incidents')}
            >
              Incidencias ({incidentReports.length})
            </button>

            {/* Animated Sliding Bar */}
            <div 
              className={`absolute bottom-[-2px] left-0 h-[4px] w-40 bg-page-blue rounded-full origin-center
                ${prevTab === 'objects' && activeTab === 'incidents' ? 'animate-slide-stretch-right' : ''}
                ${prevTab === 'incidents' && activeTab === 'objects' ? 'animate-slide-stretch-left' : ''}
              `}
              style={{ transform: activeTab === 'objects' ? 'translateX(0)' : 'translateX(100%)' }}
            />
          </div>

          <div className="bg-page-gray-light mt-4 p-4 rounded-2xl overflow-y-auto flex flex-col gap-3 flex-1 shadow-inner">
            {activeTab === 'objects' && (
              objectReports.length > 0 ? objectReports.map((report, idx) => (
                <ObjectReportCard key={idx} {...report} compact={true} className="!max-w-full shadow-sm hover:shadow-md transition-shadow" />
              )) : <EmptyState message="No hay reportes de objetos" />
            )}

            {activeTab === 'incidents' && (
              incidentReports.length > 0 ? incidentReports.map((incident, idx) => (
                <IncidentCard key={idx} {...incident} compact={true} className="!max-w-full shadow-sm hover:shadow-md transition-shadow" />
              )) : <EmptyState message="No hay incidencias reportadas" />
            )}
          </div>
        </div>
      </div>
    </Panel>
  );
};
