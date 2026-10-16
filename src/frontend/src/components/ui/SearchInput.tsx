import { useState, useRef, useEffect, useMemo } from 'react';
import { Input } from './Input';
import type { SearchOption } from '../../interfaces/SearchOption';

interface SearchInputProps {
  label?: string;
  labelColor?: string;
  options?: SearchOption[];
  value: string;
  onChange: (value: string) => void;
  onSelectOption?: (option: SearchOption) => void;
  placeholder?: string;
  icon?: React.ReactNode;
  className?: string;
  error?: string;
  showSuggestions?: boolean;
}

export const SearchInput = ({
  label,
  labelColor,
  options = [],
  value,
  onChange,
  onSelectOption,
  placeholder,
  icon,
  className = '',
  error,
  showSuggestions = true
}: SearchInputProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const lowerValue = value ? value.toLowerCase() : '';
  const hasMatches = useMemo(() => {
    if (!value) return true;
    return options.some(opt => 
      opt.label.toLowerCase().includes(lowerValue) || 
      opt.value.toLowerCase().includes(lowerValue)
    );
  }, [value, options, lowerValue]);

  const handleSelect = (opt: SearchOption) => {
    onChange(opt.label);
    if (onSelectOption) {
      onSelectOption(opt);
    }
    setIsOpen(false);
  };

  const showDropdown = showSuggestions && isOpen && hasMatches;

  return (
    <div className="relative w-full" ref={containerRef}>
      <Input
        label={label}
        labelColor={labelColor}
        value={value}
        onChange={(e) => {
          onChange(e.target.value);
          setIsOpen(true);
        }}
        onFocus={() => setIsOpen(true)}
        placeholder={placeholder}
        icon={icon}
        className={className}
        error={error}
      />

      {showSuggestions && (
        <div
          className={`absolute top-full mt-2 left-0 right-0 grid transition-all duration-500 ease-[cubic-bezier(0.16,1,0.3,1)] z-50
            ${showDropdown ? 'grid-rows-[1fr] opacity-100' : 'grid-rows-[0fr] opacity-0 pointer-events-none'}
          `}
        >
          <div className="overflow-hidden">
            <div className="bg-white border border-gray-200 rounded-[18px] shadow-[0_10px_25px_rgba(0,0,0,0.1)] p-2 max-h-60 overflow-y-auto">
              {options.map((opt, index) => {
                const isMatch = !value || opt.label.toLowerCase().includes(lowerValue) || opt.value.toLowerCase().includes(lowerValue);

                return (
                  <div
                    key={opt.value}
                    className={`grid transition-all duration-300 ease-out overflow-hidden
                      ${isMatch ? 'grid-rows-[1fr] opacity-100 mb-1 last:mb-0' : 'grid-rows-[0fr] opacity-0 mb-0'}
                    `}
                  >
                    <div className="min-h-0">
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleSelect(opt);
                        }}
                        style={{
                          transitionDelay: showDropdown && isMatch ? `${Math.min(index, 10) * 30}ms` : '0ms'
                        }}
                        className={`w-full text-left px-4 py-2.5 rounded-xl transition-all duration-300 ease-out font-medium hover:bg-gray-100 text-gray-700 hover:translate-x-2 block
                          ${showDropdown && isMatch ? 'translate-x-0' : '-translate-x-4 pointer-events-none'}
                        `}
                      >
                        {opt.label}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
