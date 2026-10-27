import { Panel } from '../../components/layout/Panel';
import AdminIcon from '../../assets/svg/icons/icon_admin.svg?react';

export const MapHeatmapPanel = () => {
  return (
    <Panel
      withUctBorder={false}
      size="lg"
      outerClassName="w-full min-h-full"
      innerClassName="p-5 h-full flex flex-col"
    >
      <div className="flex items-center gap-3">
        <AdminIcon className="w-7 h-7 shrink-0 text-page-blue" />
        <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
          Mapas de calor
        </h2>
      </div>
    </Panel>
  );
};
