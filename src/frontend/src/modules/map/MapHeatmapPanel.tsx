import { Panel } from '../../components/layout/Panel';
import { CheckboxItem } from '../../components/ui/CheckboxItem';
import AdminIcon from '../../assets/svg/icons/icon_admin.svg?react';

export type HeatmapMode = 'none' | 'reports' | 'objects';

interface MapHeatmapPanelProps {
  mode?: HeatmapMode;
  onModeChange?: (mode: HeatmapMode) => void;
}

export const MapHeatmapPanel = ({
  mode = 'none',
  onModeChange,
}: MapHeatmapPanelProps) => {
  const handleReportsToggle = () => {
    const next: HeatmapMode = mode === 'reports' ? 'none' : 'reports';
    onModeChange?.(next);
  };

  const handleObjectsToggle = () => {
    const next: HeatmapMode = mode === 'objects' ? 'none' : 'objects';
    onModeChange?.(next);
  };

  return (
    <Panel
      withUctBorder={false}
      size="lg"
      outerClassName="w-full"
      innerClassName="p-5 flex flex-col"
    >
      <div className="flex items-center gap-3">
        <AdminIcon className="w-7 h-7 shrink-0 text-page-blue" />
        <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
          Mapas de calor
        </h2>
      </div>

      <div className="flex flex-col gap-2 mt-3">
        <CheckboxItem
          label="Problemas reportados"
          className="!max-w-none"
          checked={mode === 'reports'}
          onChange={handleReportsToggle}
        />
        <CheckboxItem
          label="Objetos perdidos"
          className="!max-w-none"
          checked={mode === 'objects'}
          onChange={handleObjectsToggle}
        />
      </div>
    </Panel>
  );
};
