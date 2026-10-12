import { useState } from 'react';
import { Panel } from '../../components/layout/Panel';
import { Avatar } from '../../components/media/Avatar';
import { IconText } from '../../components/ui/IconText';
import { CloseButton } from '../../components/ui/ExitButton';
import { Button } from '../../components/ui/Button';
import { Tag } from '../../components/ui/Tag';
import type { Role } from '../../constants/role';
import type { PageColor } from '../../constants/colors';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';
import StudyIcon from '../../assets/svg/icons/icon_study.svg?react';
import CalendarIcon from '../../assets/svg/icons/icon_calendar.svg?react';
import { ObjectReportCard } from '../objects/ObjectReportCard';
import { IncidentCard } from '../incidents/IncidentCard';
import { EmptyState } from '../../components/ui/EmptyState';

export interface UserProfilePanelProps {
  name: string;
  admissionYear: string;
  career: string;
  email: string;
  photoUrl?: string;
  role?: Role;
  objectReports?: any[];
  incidentReports?: any[];
  onClose?: () => void;
  onLogout?: () => void;
}

const getRoleConfig = (role?: Role): { label: string; color: PageColor } => {
  if (!role) return { label: 'ESTUDIANTE', color: 'blue' };

  switch (role) {
    case 'ADMIN': return { label: 'ADMINISTRADOR', color: 'purple' };
    case 'INCIDENTS_OFFICER': return { label: 'ENC. INCIDENTES', color: 'blue' };
    case 'OBJECTS_OFFICER': return { label: 'ENC. OBJETOS', color: 'blue' };
    case 'TEACHER': return { label: 'PROFESOR', color: 'dark' };
    case 'OFFICIAL': return { label: 'FUNCIONARIO', color: 'green' };
    case 'MEMBER': return { label: 'ESTUDIANTE', color: 'blue' };
    default: return { label: 'USUARIO', color: 'gray' };
  }
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
  onClose,
  onLogout,
}: UserProfilePanelProps) => {
  const [activeTab, setActiveTab] = useState<'objects' | 'incidents'>('objects');
  const [prevTab, setPrevTab] = useState<'objects' | 'incidents'>('objects');

  const roleConfig = getRoleConfig(role);

  const handleTabChange = (tab: 'objects' | 'incidents') => {
    if (tab !== activeTab) {
      setPrevTab(activeTab);
      setActiveTab(tab);
    }
  };

  return (
    <Panel color="white" withUctBorder={true} outerClassName="w-[1100px] max-w-full" innerClassName="p-8 flex flex-col relative min-h-[650px] max-h-[85vh]">
      {/* Close button positioned top-right */}
      <div className="absolute top-6 right-6">
        <CloseButton onClick={onClose} variant="ghost" size="md" />
      </div>

      <div className="flex flex-col lg:flex-row gap-10 mt-6 lg:mt-0 flex-1 overflow-hidden">
        
        {/* Left Section: Profile Info */}
        <div className="flex flex-col items-center w-full lg:w-1/3 flex-shrink-0 lg:pt-4 overflow-y-auto pb-4">
          <h3 className="text-2xl font-black text-gray-700 uppercase tracking-widest mb-6 w-full text-center">Información de Cuenta</h3>
          
          <Avatar src={photoUrl} className="w-64 h-64 mb-6 shadow-xl" />
          
          <h2 className="text-3xl font-black text-gray-800 uppercase text-center leading-tight mb-3">{name}</h2>
          
          <Tag
            label={roleConfig.label}
            color={roleConfig.color}
            className="mb-6 !text-base !px-4 !py-1 shadow-sm"
          />
          
          <div className="flex flex-col gap-5 w-full px-4 mb-10">
            <IconText icon={<CalendarIcon className="w-[1.2em] h-[1.2em]" />} text={`Ingreso: ${admissionYear}`} className="!text-xl font-medium" />
            <IconText icon={<StudyIcon className="w-[1.2em] h-[1.2em]" />} text={career} className="!text-xl font-medium leading-snug" />
            <IconText icon={<MailIcon className="w-[1.2em] h-[1.2em]" />} text={email} className="!text-xl font-medium break-all" />
          </div>

          <Button variant="outline" color="red" className="w-max px-8 font-bold tracking-wide" onClick={onLogout}>
            CERRAR SESIÓN
          </Button>
        </div>

        {/* Vertical Divider */}
        <div className="hidden lg:block w-px bg-gray-200"></div>
        <hr className="block lg:hidden border-t-2 border-gray-200 w-full" />

        {/* Right Section: Reports */}
        <div className="flex flex-col flex-1 w-full min-w-0 lg:pt-4 h-full">
          <h3 className="text-2xl font-black text-gray-700 uppercase tracking-widest mb-2 px-2">Tus Contribuciones</h3>
          
          <div className="relative flex border-b-2 border-gray-200 mt-2 flex-shrink-0">
            <button 
              className={`w-56 text-xl font-bold py-3 transition-colors z-10
                ${activeTab === 'objects' ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}
              `}
              onClick={() => handleTabChange('objects')}
            >
              Objetos ({objectReports.length})
            </button>
            <button 
              className={`w-56 text-xl font-bold py-3 transition-colors z-10
                ${activeTab === 'incidents' ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}
              `}
              onClick={() => handleTabChange('incidents')}
            >
              Incidencias ({incidentReports.length})
            </button>

            {/* Animated Sliding Bar */}
            <div 
              className={`absolute bottom-[-2px] left-0 h-[4px] w-56 bg-page-blue rounded-full origin-center
                ${prevTab === 'objects' && activeTab === 'incidents' ? 'animate-slide-stretch-right' : ''}
                ${prevTab === 'incidents' && activeTab === 'objects' ? 'animate-slide-stretch-left' : ''}
              `}
              style={{ transform: activeTab === 'objects' ? 'translateX(0)' : 'translateX(100%)' }}
            />
          </div>

          <div className="bg-page-gray-light mt-6 p-6 rounded-3xl overflow-y-auto flex flex-col gap-4 flex-1 shadow-inner">
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
