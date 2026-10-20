import { Panel } from '../../components/layout/Panel';

interface MapSidePanelProps {
  onClose: () => void;
}

export const MapSidePanel = ({ onClose }: MapSidePanelProps) => {
  return (
    <Panel
      withUctBorder={false}
      size="sm"
      outerClassName="w-full min-h-full"
      innerClassName="p-5 h-full flex flex-col"
      onClose={onClose}
    >
      <div className="flex-1" />
    </Panel>
  );
};
