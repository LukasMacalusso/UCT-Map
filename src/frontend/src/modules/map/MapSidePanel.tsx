import { Panel } from '../../components/layout/Panel';
import { CloseButton } from '../../components/ui/ExitButton';

interface MapSidePanelProps {
  onClose: () => void;
}

export const MapSidePanel = ({ onClose }: MapSidePanelProps) => {
  return (
    <Panel
      withUctBorder={false}
      size="lg"
      outerClassName="w-full min-h-full"
      innerClassName="p-5 h-full flex flex-col"
    >
      <div className="flex items-start justify-between gap-2">
        <h2 className="text-xl font-extrabold text-gray-800 leading-tight uppercase tracking-tight">
          Filtros
        </h2>
        <CloseButton variant="ghost" size="lg" onClick={onClose} />
      </div>

      <div className="flex-1" />
    </Panel>
  );
};
