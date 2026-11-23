import { type PageColor, bgPageColors, solidButtonConfig } from '../../constants/colors';

interface TagProps {
  label: string;
  icon?: React.ReactNode;
  color?: PageColor;
  className?: string;
}

export const Tag = ({ label, icon, color = 'blue', className = '' }: TagProps) => {
  const textClass = solidButtonConfig[color]?.text || "text-inherit";
  const borderClass = color === 'white' ? "border border-page-gray-medium" : "";

  return (
    <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full font-bold text-sm ${bgPageColors[color]} ${textClass} ${borderClass} ${className}`}>
      {icon && <span className="flex items-center justify-center">{icon}</span>}
      <span>{label}</span>
    </div>
  );
};
