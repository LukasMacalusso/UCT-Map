import { useEffect } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { SectionButton } from '../ui/SectionButton';
import { Avatar } from '../media/Avatar';
import { Tag } from '../ui/Tag';
import { useNavStore } from '../../states/navState';
import { useAuthState } from '../../states/authState';
import type { PageColor } from '../../constants/colors';
import { Role, ROLE_STYLES } from '../../constants/role';

import logoUrl from '../../assets/svg/logo.svg';
import MapIcon from '../../assets/svg/icons/icon_section_map.svg?react';
import ReportsIcon from '../../assets/svg/icons/icon_section_incidents.svg?react';
import ObjectsIcon from '../../assets/svg/icons/icon_section_objects.svg?react';
import ContactsIcon from '../../assets/svg/icons/icon_section_contacts.svg?react';
import AdminIcon from '../../assets/svg/icons/icon_admin.svg?react';
import UserIcon from '../../assets/svg/icons/icon_user.svg?react';
import { RoleGuard } from '../../router/RoleGuard';
import { GlobalModals } from './GlobalModals';
import { useUiState } from '../../states/uiState';

export const AppLayout = () => {
  const { isExpanded, isHidden, setIsExpanded, setIsHidden } = useNavStore();
  const location = useLocation();
  const user = useAuthState((state) => state.user);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() !== 'h' || event.ctrlKey || event.metaKey || event.altKey) return;
      const target = event.target as HTMLElement | null;
      if (target && (target.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(target.tagName))) return;
      setIsHidden(!isHidden);
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isHidden, setIsHidden]);

  useEffect(() => {
    const timeout = window.setTimeout(() => window.dispatchEvent(new Event('resize')), 320);
    return () => window.clearTimeout(timeout);
  }, [isHidden]);

  const getRoleConfig = (role?: Role): { label: string; color: PageColor } => {
    if (!role) return { label: 'INVITADO', color: 'gray' };
    return ROLE_STYLES[role];
  };

  const roleConfig = getRoleConfig(user?.role);

  const getPageTitle = (path: string) => {
    if (path.includes('/map')) return 'Mapa';
    if (path.includes('/reports')) return 'Reportes';
    if (path.includes('/objects')) return 'Objetos';
    if (path.includes('/contacts')) return 'Contactos';
    if (path.includes('/showcase')) return 'Showcase';
    if (path.includes('/administration')) return 'Administración';
    return '';
  };

  const pageTitle = getPageTitle(location.pathname);

  return (
    <div className="flex h-screen bg-page-dark overflow-hidden font-sans relative">

      <div
        className={`flex-shrink-0 h-full bg-page-blue z-0 transition-all duration-300 ${
          isHidden ? 'w-0' : 'w-[88px]'
        }`}
      />

      <nav
        className={`absolute left-0 top-0 bottom-0 bg-page-blue flex flex-col gap-4 py-8 px-4 h-full shadow-xl transition-all duration-300 z-50 ${
          isHidden ? '-translate-x-full opacity-0 pointer-events-none' : 'translate-x-0 opacity-100'
        } ${
          isExpanded ? 'w-[320px]' : 'w-[88px]'
        }`}
        onMouseEnter={() => !isHidden && setIsExpanded(true)}
        onMouseLeave={() => setIsExpanded(false)}
      >
        {/* LOGO CONTAINER */}
        <div
          className={`flex items-center mb-4 bg-white rounded-2xl relative transition-all duration-300 ease-in-out shadow-md flex-shrink-0 z-50 w-max overflow-hidden ${
            isExpanded ? 'h-24 min-w-[288px] pr-2' : 'h-14 min-w-0 pr-4'
          }`}
        >
          {/* LOGO */}
          <div className={`flex-shrink-0 flex items-center justify-center z-10 transition-all duration-300 ease-in-out ${isExpanded ? 'w-24 h-24' : 'w-14 h-14'}`}>
            <img
              src={logoUrl}
              alt="UCT Logo"
              className={`object-contain transition-all duration-300 ease-in-out ${isExpanded ? 'w-20 h-20' : 'w-10 h-10'}`}
            />
          </div>

          <div className="flex items-center h-full">
            <div
              className={`flex flex-col justify-center transition-all duration-300 ease-in-out overflow-hidden whitespace-nowrap ${
                !isExpanded
                  ? 'max-w-[250px] opacity-100 ml-1'
                  : 'max-w-0 opacity-0 ml-0'
              }`}
            >
              <span className="text-gray-800 font-medium text-2xl">
                {pageTitle}
              </span>
            </div>

            {/* LOGO TEXT */}
            <div
              className={`flex flex-col justify-center transition-all duration-300 ease-in-out overflow-hidden whitespace-nowrap ${
                isExpanded
                  ? 'max-w-[250px] opacity-100 ml-3'
                  : 'max-w-0 opacity-0 ml-0'
              }`}
            >
              <span className="text-gray-800 font-black text-3xl leading-none tracking-wide block">UCT</span>
              <span className="text-gray-800 font-black text-3xl leading-none tracking-wide block">MAP</span>
            </div>
          </div>
        </div>

        <SectionButton
          to="/map"
          label="Mapa"
          isExpanded={isExpanded}
          expandedWidth="288px"
          icon={<MapIcon className="w-8 h-8" />}
        />

        <SectionButton
          to="/reports"
          label="Reportes"
          isExpanded={isExpanded}
          expandedWidth="288px"
          icon={<ReportsIcon className="w-8 h-8" />}
        />

        <SectionButton
          to="/objects"
          label="Objetos"
          isExpanded={isExpanded}
          expandedWidth="288px"
          icon={<ObjectsIcon className="w-8 h-8" />}
        />

        <SectionButton
          to="/contacts"
          label="Contactos"
          isExpanded={isExpanded}
          expandedWidth="288px"
          icon={<ContactsIcon className="w-8 h-8" />}
        />

        <RoleGuard allowedRoles={[Role.Admin]}>
          <SectionButton
            to="/administration"
            label="Administración"
            isExpanded={isExpanded}
            expandedWidth="288px"
            icon={<AdminIcon className="w-8 h-8" />}
          />
        </RoleGuard>

        {/* User Info Container or Login Button */}
        <div className="mt-auto">
          {user ? (
            <button
              type="button"
              onClick={() => useUiState.getState().openPanel('userProfile')}
              className={`flex items-center rounded-2xl relative transition-all duration-300 ease-in-out flex-shrink-0 z-50 overflow-hidden text-left cursor-pointer hover:brightness-95 active:scale-[0.98] ${
                isExpanded ? 'bg-white shadow-md h-24 w-[288px] p-2 pr-4' : 'bg-transparent h-14 w-14 p-0'
              }`}
              title="Información de cuenta"
            >
              {/* Avatar*/}
              <div className={`flex-shrink-0 flex items-center justify-center z-10 transition-all duration-300 ease-in-out ${isExpanded ? 'w-20 h-20' : 'w-14 h-14'}`}>
                <Avatar className="w-full h-full" src={user.avatar} />
              </div>

              {/* User texts */}
              <div
                className={`flex flex-col justify-center transition-all duration-300 ease-in-out overflow-hidden whitespace-normal break-words ${
                  isExpanded
                    ? 'max-w-[190px] opacity-100 ml-3'
                    : 'max-w-0 opacity-0 ml-0'
                }`}
              >
                <span className="text-gray-800 font-bold text-lg leading-tight line-clamp-2">
                  {user.name}
                </span>
                <Tag
                  label={roleConfig.label}
                  color={roleConfig.color}
                  className="mt-1 w-max scale-90 origin-left"
                />
              </div>
            </button>
          ) : (
            <SectionButton
              to="/login"
              label="Iniciar Sesión"
              isExpanded={isExpanded}
              expandedWidth="288px"
              icon={<UserIcon className="w-8 h-8" />}
            />
          )}
        </div>
      </nav>

      {/* BACKDROP
        */}
      <div
        className={`absolute inset-0 bg-black transition-opacity duration-300 z-40 pointer-events-none ${
          isExpanded && !isHidden ? 'opacity-50' : 'opacity-0'
        }`}
        style={{ left: '88px' }}
      />

      <main className="flex-1 relative overflow-auto bg-page-dark z-10">
        <Outlet />
      </main>

      {/* GLOBAL MODALS CONTAINER */}
      <GlobalModals />
    </div>
  );
};
