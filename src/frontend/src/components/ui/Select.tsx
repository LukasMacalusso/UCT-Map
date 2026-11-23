import React, { useState, useRef, useEffect } from 'react';

interface SelectProps extends Omit<React.SelectHTMLAttributes<HTMLSelectElement>, 'onChange'> {
  label?: string;
  labelColor?: string;
  options: { value: string; label: string }[];
  error?: string;
  value?: string;
  onChange?: (value: string) => void;
  icon?: React.ReactNode;
}

export const Select = React.forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, labelColor = 'text-white', options, error, className = '', value, onChange, icon, ...props }, ref) => {
    const [isOpen, setIsOpen] = useState(false);
    const [selectedValue, setSelectedValue] = useState(value || '');
    const containerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
      if (value !== undefined) {
        setSelectedValue(value);
      }
    }, [value]);

    useEffect(() => {
      const handleClickOutside = (event: MouseEvent) => {
        if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
          setIsOpen(false);
        }
      };
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const handleSelect = (val: string) => {
      setSelectedValue(val);
      setIsOpen(false);
      if (onChange) {
        onChange(val);
      }
    };

    const selectedLabel = options.find(o => o.value === selectedValue)?.label || 'Selecciona una opción';

    return (
      <div className="flex flex-col gap-1 w-full relative" ref={containerRef}>
        {label && (
          <label className={`text-sm font-semibold ${labelColor}`}>
            {label}
          </label>
        )}

        <div className="relative w-full">

          <button
            type="button"
            onClick={() => setIsOpen(!isOpen)}
            className={`flex items-center justify-between w-full px-4 py-3 border-2 rounded-[18px] outline-none bg-white transition-colors duration-200 cursor-pointer z-10 relative
              ${error ? 'border-red-300' : 'border-gray-400'}
              ${className}
            `}
          >
            <span className={`font-medium flex items-center gap-2 whitespace-nowrap ${selectedValue ? 'text-gray-900' : 'text-gray-500'}`}>
              {icon && <span className="text-page-dark flex items-center flex-shrink-0">{icon}</span>}
              <span className="whitespace-nowrap">{selectedLabel}</span>
            </span>

            <svg
              className={`w-5 h-5 text-gray-400 transition-transform duration-300 ease-[cubic-bezier(0.16,1,0.3,1)] ${isOpen ? 'rotate-180' : ''}`}
              fill="none" stroke="currentColor" viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>


          <div
            className={`absolute inset-0 rounded-[18px] pointer-events-none p-[4px] transition-[clip-path] duration-300 ease-out z-20
              ${error
                ? 'animate-error-pulse [clip-path:inset(-10px_-10px_-10px_-10px)]'
                : `bg-[linear-gradient(to_right,var(--color-page-blue)_50%,var(--color-page-yellow)_50%)] ${isOpen ? '[clip-path:inset(-10px_-10px_-10px_-10px)]' : '[clip-path:inset(-10px_100%_-10px_0)]'}`
              }
            `}
            style={{
              WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
              WebkitMaskComposite: 'xor',
              maskComposite: 'exclude'
            }}
          />
        </div>


        <div
          className={`absolute top-[calc(100%+0.5rem)] left-0 right-0 grid transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] z-50
            ${isOpen ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0 pointer-events-none'}
          `}
        >
          <div className="overflow-hidden">

            <div className="bg-white border border-gray-200 rounded-[18px] shadow-[0_10px_25px_rgba(0,0,0,0.1)] p-2 flex flex-col gap-1 max-h-60 overflow-y-auto">
              {options.map((opt, index) => (
                <div
                  key={opt.value}
                  style={{

                    transitionDelay: isOpen ? `${index * 40}ms` : '0ms'
                  }}
                  className={`transition-all duration-500 ease-out
                    ${isOpen ? 'opacity-100 translate-x-0' : 'opacity-0 -translate-x-4 pointer-events-none'}
                  `}
                >
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleSelect(opt.value);
                    }}
                    className={`w-full text-left px-4 py-2.5 rounded-xl transition-all duration-200 ease-out font-medium
                      ${selectedValue === opt.value ? 'bg-blue-50 text-page-blue' : 'hover:bg-gray-100 text-gray-700 hover:translate-x-2'}
                    `}
                  >
                    {opt.label}
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>


        <select ref={ref} value={selectedValue} className="hidden" disabled {...props}>
          <option value={selectedValue}>{selectedLabel}</option>
        </select>

        {error && <span className="text-xs text-red-500 pl-4">{error}</span>}
      </div>
    );
  }
);

Select.displayName = 'Select';
