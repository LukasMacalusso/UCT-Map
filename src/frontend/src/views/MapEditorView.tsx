import { Outlet, useLocation, useNavigate } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { useUiState } from '../states/uiState';

import MapIcon from '../assets/svg/icons/icon_section_map.svg?react';
import CampusIcon from '../assets/svg/icons/icon_location.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import CheckIcon from '../assets/svg/icons/icon_check.svg?react';
import CrossIcon from '../assets/svg/icons/icon_cross.svg?react';

const EDITOR_SECTIONS = [
  { path: '/edition/map', label: 'MAPA', icon: MapIcon },
  { path: '/edition/campus', label: 'CAMPUS', icon: CampusIcon },
  { path: '/edition/buildings', label: 'EDIFICIOS', icon: BuildingIcon },
  { path: '/edition/filters', label: 'FILTROS', icon: FilterIcon },
] as const;

export const MapEditorView = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const changesCount: number = 0;

  return (
    <div className="w-full h-screen bg-page-dark flex flex-col overflow-hidden">
      {/* Active Sub-View Area */}
      <div className="flex-1 min-h-0 relative overflow-hidden">
        <Outlet />
      </div>

      {/* Full-Width Bottom White Strip */}
      <div className="w-full bg-white px-6 py-3 flex flex-row items-center justify-between gap-4 flex-shrink-0 z-30 shadow-lg">
        {/* Left spacer to keep navigation buttons centered or balanced */}
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

        {/* Right Side: "n cambios" + Guardar & Descartar */}
        <div className="flex items-center gap-3">
          <span className="text-sm font-bold text-gray-600 uppercase tracking-wide whitespace-nowrap mr-1">
            {changesCount} {changesCount === 1 ? 'cambio' : 'cambios'}
          </span>

          <Button
            variant="solid"
            color="green"
            size="md"
            className="!w-auto px-5 font-bold uppercase tracking-wide flex items-center justify-center gap-2"
            onClick={() => useUiState.getState().openPanel('saveMapChanges')}
          >
            <CheckIcon className="w-5 h-5" />
            GUARDAR
          </Button>

          <Button
            variant="outline"
            color="red"
            size="md"
            className="!w-auto px-5 font-bold uppercase tracking-wide flex items-center justify-center gap-2"
            onClick={() => useUiState.getState().openPanel('discardMapChanges')}
          >
            <CrossIcon className="w-5 h-5" />
            DESCARTAR
          </Button>
        </div>
      </div>
    </div>
  );
};
