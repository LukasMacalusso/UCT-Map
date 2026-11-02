
interface IconTextProps {
  icon: React.ReactNode;
  text: string;
  className?: string;
  color?: string;
}

export const IconText = ({ icon, text, className = '', color }: IconTextProps) => {
  return (
    <div
      className={`flex items-center gap-2 font-medium text-xl ${!color ? 'text-page-dark' : ''} ${className}`}
      style={color ? { color } : undefined}
    >
      <span className="flex items-center justify-center flex-shrink-0">
        {icon}
      </span>
      <span className="min-w-0 truncate">{text}</span>
    </div>
  );
};
