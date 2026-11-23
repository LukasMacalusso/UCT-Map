import React from 'react';

interface CheckboxItemProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  desc?: string;
  icon?: React.ReactNode;
}

export const CheckboxItem = React.forwardRef<HTMLInputElement, CheckboxItemProps>(({
  label,
  desc = "",
  icon,
  className = '',
  ...props },
  ref) => {
    return (
      <label className={`group flex items-center justify-between px-4 py-3 bg-page-gray-light rounded-xl cursor-pointer hover:brightness-95 transition-all w-full max-w-sm ${className}`}>
        {/* ICON */}
        <div className="flex items-center gap-3 transition-transform duration-300 ease-out group-hover:translate-x-1">
          {icon && (
            <span className="text-page-dark flex items-center justify-center text-2xl flex-shrink-0">
              {icon}
            </span>
          )}

          {/* TITLE AND DESC */}
          <div className="flex flex-col text-left">
            <span className="text-page-dark font-medium text-lg leading-tight">
              {label}
            </span>
            {desc && (
              <span className="text-page-dark text-sm">
                {desc}
              </span>
            )}
          </div>
        </div>

        {/* CHECKBOX CONTAINER */}
        <div className="relative w-7 h-7 flex items-center justify-center rounded-md border-[3.5px] border-page-dark overflow-hidden">
          <input
            type="checkbox"
            ref={ref}
            className="peer absolute inset-0 opacity-0 cursor-pointer z-10 outline-none focus-visible:ring-2 focus-visible:ring-page-blue"
            {...props}
          />
          <span
            className="absolute w-10 h-10 rounded-full bg-page-yellow scale-0 transition-transform duration-300 ease-out peer-checked:scale-100 pointer-events-none"
            aria-hidden="true"
          />
        </div>
      </label>
    );
  }
);

CheckboxItem.displayName = 'CheckboxItem';
