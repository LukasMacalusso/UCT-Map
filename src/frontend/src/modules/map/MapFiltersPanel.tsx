import { Panel } from '../../components/layout/Panel';
import { CheckboxItem } from '../../components/ui/CheckboxItem';
import type { FilterSection } from '../../interfaces/FilterSection';

interface MapFiltersPanelProps {
  title: string;
  sections: FilterSection[];
  onToggleItem?: (sectionId: string, itemId: string) => void;
  className?: string;
}

export const MapFiltersPanel = ({ title, sections, onToggleItem, className = '' }: MapFiltersPanelProps) => {
  return (
    <Panel
      color="white"
      withUctBorder={false}
      outerClassName={`shadow-lg rounded-2xl w-[320px] ${className}`}
      innerClassName="p-5 flex flex-col max-h-[60vh]"
    >
      {/* HEADER */}
      <div className="flex items-center justify-between mb-4 flex-shrink-0">
        <h2 className="text-2xl font-medium text-gray-800">{title}</h2>
      </div>

      {/* SECTIONS */}
      <div className="flex flex-col gap-5 overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-gray-300">
        {sections.map((section) => (
          <div key={section.id} className="flex flex-col gap-2">
            <h3 className="text-xs font-bold text-gray-600 tracking-wider uppercase mb-1">
              {section.title}
            </h3>
            <div className="flex flex-col gap-2">
              {section.items.map((item) => (
                <CheckboxItem
                  key={item.id}
                  label={item.label}
                  icon={item.icon}
                  checked={item.checked}
                  onChange={() => onToggleItem?.(section.id, item.id)}
                  className="!p-2 !rounded-[14px]"
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </Panel>
  );
};
