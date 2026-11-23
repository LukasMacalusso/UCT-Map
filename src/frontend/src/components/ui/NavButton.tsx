import { NavLink } from 'react-router-dom';

type NavButtonSize = 'sm' | 'md' | 'lg';
type NavButtonWidth = 'auto' | 'sm' | 'md' | 'lg' | 'full';

interface NavButtonProps {
  to: string;
  icon?: React.ReactNode;
  label?: string;
  size?: NavButtonSize;
  width?: NavButtonWidth;
}

export const NavButton = ({
  to,
  icon,
  label,
  size = 'md',
  width = 'auto'
}: NavButtonProps) => {

  const sizeConfig: Record<NavButtonSize, { padding: string; text: string; gap: string }> = {
    sm: { padding: 'px-3 py-1.5', text: 'text-sm', gap: 'gap-1.5' },
    md: { padding: 'px-4 py-2', text: 'text-base', gap: 'gap-2' },
    lg: { padding: 'px-6 py-3', text: 'text-lg', gap: 'gap-3' },
  };

  const widthConfig: Record<NavButtonWidth, string> = {
    auto: 'w-auto',
    sm: 'w-32 flex-shrink-0 justify-center',
    md: 'w-48 flex-shrink-0 justify-center',
    lg: 'w-64 flex-shrink-0 justify-center',
    full: 'w-full justify-start',
  };

  const { padding, text, gap } = sizeConfig[size];
  const widthClasses = widthConfig[width];

  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        `relative overflow-hidden group flex items-center rounded-md font-medium transition-colors duration-200 z-0 ${padding} ${text} ${gap} ${widthClasses} ${
          isActive
            ? 'bg-page-blue text-white shadow-md'
            : 'bg-transparent text-gray-700 hover:text-page-blue'
        }`
      }
    >
      {({ isActive }) => (
        <>
          {!isActive && (
            <div className="absolute inset-0 bg-blue-100 origin-left scale-x-0 transition-transform duration-300 ease-out group-hover:scale-x-100 -z-10 rounded-md" />
          )}
          {icon && <span className="flex items-center relative z-10">{icon}</span>}
          <span className="relative z-10">{label}</span>
        </>
      )}
    </NavLink>
  );
};
