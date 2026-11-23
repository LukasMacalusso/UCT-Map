import { NavLink } from 'react-router-dom';

interface SectionButtonProps {
  to: string;
  icon?: React.ReactNode;
  label?: string;
  expandedWidth?: string;
  isExpanded?: boolean;
}

export const SectionButton = ({
  to,
  icon,
  label,
  expandedWidth = "200px",
  isExpanded = false
}: SectionButtonProps) => {
  return (
    <NavLink
      to={to}
      style={{ '--expanded-width': expandedWidth } as React.CSSProperties}
      className={({ isActive }) =>
        `relative flex items-center h-14 rounded-2xl transition-all duration-300 ease-in-out cursor-pointer overflow-hidden ${
          isExpanded ? 'w-[var(--expanded-width)]' : 'w-14'
        } ${
          isActive ? 'bg-page-white shadow-md' : 'bg-page-white shadow-sm hover:shadow-md'
        } active:scale-95`
      }
    >
      {({ isActive }) => (
        <>
          {/* ICON CONTAINER */}
          <div className={`flex-shrink-0 flex items-center justify-center w-14 h-14 rounded-2xl transition-colors duration-300 ${
            isActive
              ? 'bg-page-yellow text-page-white'
              : 'bg-transparent text-page-blue'
          }`}>
            <span className={`flex items-center justify-center w-8 h-8 transition-transform duration-500 ease-[cubic-bezier(0.34,1.56,0.64,1)] ${
              isActive ? 'scale-110' : 'scale-100 group-hover:scale-105'
            }`}>
              {icon}
            </span>
          </div>

          {/* TEXT CONTAINER */}
          <span
            className={`ml-3 whitespace-nowrap text-2xl font-medium text-gray-800 transition-all duration-300 ${
              isExpanded
                ? 'opacity-100 translate-x-0 delay-[100ms]'
                : 'opacity-0 -translate-x-4 pointer-events-none'
            }`}
          >
            {label}
          </span>
        </>
      )}
    </NavLink>
  );
};
