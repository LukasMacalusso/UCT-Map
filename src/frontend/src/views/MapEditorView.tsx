import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { useUiState } from '../states/uiState';

import MapIcon from '../assets/svg/icons/icon_section_map.svg?react';
import CampusIcon from '../assets/svg/icons/icon_location.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';

const EDITOR_SECTIONS = [
  { path: '/edition/map', label: 'MAPA', icon: MapIcon },
  { path: '/edition/campus', label: 'CAMPUS', icon: CampusIcon },
  { path: '/edition/buildings', label: 'EDIFICIOS', icon: BuildingIcon },
  { path: '/edition/filters', label: 'FILTROS', icon: FilterIcon },
] as const;

export const MapEditorView = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const editorToast = useUiState((state) => state.editorToast);

  return (
    <div className="w-full h-screen bg-transparent flex flex-col overflow-hidden">
      {/* Active Sub-View Area */}
      <div className="flex-1 min-h-0 relative overflow-hidden">
        <Outlet />
      </div>

      {/* Full-Width Bottom White Strip */}
      <div className="w-full bg-white px-6 py-3 flex flex-row items-center justify-between gap-4 flex-shrink-0 z-30 shadow-lg relative min-h-[4rem]">
        {/* Left: Navigation Buttons */}
        <div className="flex items-center gap-3">
          {EDITOR_SECTIONS.map(({ path, label, icon: Icon }) => {
            const isActive = location.pathname.startsWith(path);
            return (
              <Button
                key={path}
                variant={isActive ? 'solid' : 'outline'}
                color="blue"
                size="md"
                width="md"
                onClick={() => navigate(path)}
                className="font-bold uppercase tracking-wide flex items-center justify-center gap-2"
              >
                <Icon className="w-5 h-5" />
                {label}
              </Button>
            );
          })}
        </div>

        {/* Right: Update / Success Feedback Toast */}
        <div className="flex items-center justify-end overflow-hidden py-1 min-h-[2.5rem]">
          {editorToast && (
            <div
              key={editorToast.id}
              className={`animate-toast-expo flex items-center px-4 py-2 rounded-xl text-xs font-bold shadow-xs will-change-transform ${
                editorToast.type === 'error'
                  ? 'bg-red-50 border border-red-200 text-page-red'
                  : editorToast.type === 'info'
                  ? 'bg-blue-50 border border-blue-200 text-page-blue'
                  : 'bg-emerald-50 border border-emerald-200 text-emerald-800'
              }`}
            >
              <span>{editorToast.message}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
