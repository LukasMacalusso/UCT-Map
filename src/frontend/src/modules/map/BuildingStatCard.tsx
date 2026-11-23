import type { ReactNode } from 'react';

interface BuildingStatCardProps {
  icon: ReactNode;
  label: string;
  value: string;
}

export const BuildingStatCard = ({ icon, label, value }: BuildingStatCardProps) => (
  <div className="bg-page-gray-light rounded-2xl px-4 py-3 flex items-center gap-3">
    <div className="w-9 h-9 rounded-xl bg-white flex items-center justify-center flex-shrink-0">
      {icon}
    </div>
    <div className="flex flex-col min-w-0">
      <span className="text-[0.65rem] font-bold text-gray-500 uppercase tracking-wider">
        {label}
      </span>
      <span className="text-sm font-bold text-gray-800 truncate">{value}</span>
    </div>
  </div>
);
