import React from 'react';

type InputProps = {
  label?: string;
  labelColor?: string;
  error?: string;
  multiline?: boolean;
  icon?: React.ReactNode;
  rightElement?: React.ReactNode;
} & React.InputHTMLAttributes<HTMLInputElement> & React.TextareaHTMLAttributes<HTMLTextAreaElement>;

export const Input = React.forwardRef<any, InputProps>(
  ({ label, labelColor = 'text-white', error, className = '', multiline, icon, rightElement, placeholder, ...props }, ref) => {
    const inputPlaceholder = placeholder !== undefined ? placeholder : (props as any).placeholder;
    const paddingClass = `${icon ? 'pl-12' : 'pl-4'} ${rightElement ? 'pr-12' : 'pr-4'}`;

    return (
      <div className="flex flex-col gap-1 w-full relative">
        {label && (
          <label className={`text-sm font-semibold ${labelColor}`}>
            {label}
          </label>
        )}

        <div className="relative w-full">
          {icon && (
            <div className="absolute left-4 top-1/2 -translate-y-1/2 z-20 text-gray-700 flex items-center justify-center pointer-events-none">
              {icon}
            </div>
          )}

          {multiline ? (
            <textarea
              ref={ref}
              placeholder={inputPlaceholder}
              className={`peer w-full ${paddingClass} py-3 border-2 rounded-[18px] outline-none bg-white relative z-10 transition-colors
                placeholder:text-gray-400 placeholder:opacity-100 text-gray-900 font-medium
                ${error ? 'border-red-300' : 'border-gray-400'}
                ${className}
              `}
              {...(props as any)}
            />
          ) : (
            <input
              ref={ref}
              placeholder={inputPlaceholder}
              className={`peer w-full ${paddingClass} py-3 border-2 rounded-[18px] outline-none bg-white relative z-10 transition-colors
                placeholder:text-gray-400 placeholder:opacity-100 text-gray-900 font-medium
                ${error ? 'border-red-300' : 'border-gray-400'}
                ${className}
              `}
              {...(props as any)}
            />
          )}

          <div
            className={`absolute inset-0 rounded-[18px] pointer-events-none p-[4px] transition-[clip-path] duration-300 ease-out z-20
              ${error
                ? 'animate-error-pulse [clip-path:inset(-10px_-10px_-10px_-10px)]'
                : 'bg-[linear-gradient(to_right,var(--color-page-blue)_50%,var(--color-page-yellow)_50%)] [clip-path:inset(-10px_100%_-10px_0)] peer-focus:[clip-path:inset(-10px_-10px_-10px_-10px)]'
              }
            `}
            style={{
              WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
              WebkitMaskComposite: 'xor',
              maskComposite: 'exclude'
            }}
          />

          {rightElement && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 z-30 flex items-center">
              {rightElement}
            </div>
          )}
        </div>

        {error && <span className="text-xs text-red-500 pl-4">{error}</span>}
      </div>
    );
  }
);

Input.displayName = 'Input';
