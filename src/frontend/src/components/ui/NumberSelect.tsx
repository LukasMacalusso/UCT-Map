import { useState, useEffect, useRef } from 'react';
import PlusIcon from '../../assets/svg/icons/icon_plus.svg?react';
import MinusIcon from '../../assets/svg/icons/icon_minus.svg?react';

export interface NumberSelectProps {
  initialValue?: number;
  multiplier?: number;
  isFloat?: boolean;
  min?: number;
  max?: number;
  variant?: 'horizontal' | 'vertical';
  onChange?: (value: number) => void;
  label?: string;
}

export const NumberSelect = ({
  initialValue = 0,
  multiplier = 1,
  isFloat = false,
  min = -Infinity,
  max = Infinity,
  variant = 'horizontal',
  onChange,
  label
}: NumberSelectProps) => {
  const [renderValue, setRenderValue] = useState<number>(initialValue);
  const [prevInitialValue, setPrevInitialValue] = useState<number>(initialValue);
  const [animatingValue, setAnimatingValue] = useState<number | null>(null);
  const [direction, setDirection] = useState<'increase' | 'decrease' | null>(null);
  const [errorPulse, setErrorPulse] = useState(false);

  if (initialValue !== prevInitialValue) {
    setPrevInitialValue(initialValue);
    setRenderValue(initialValue);
  }

  // Refs for auto-repeat
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const valueRef = useRef<number>(renderValue);

  useEffect(() => {
    valueRef.current = initialValue;
  }, [initialValue]);

  const formatValue = (val: number) => {
    let newVal = isFloat ? val : Math.round(val);
    if (newVal < min) newVal = min;
    if (newVal > max) newVal = max;
    return isFloat ? Number(newVal.toFixed(2)) : newVal;
  };

  const triggerError = () => {
    setErrorPulse(true);
    setTimeout(() => setErrorPulse(false), 400);
  };

  const triggerAnimation = (newVal: number, type: 'increase' | 'decrease') => {
    if (newVal === valueRef.current) return;

    setDirection(type);
    setAnimatingValue(valueRef.current);

    setRenderValue(newVal);
    valueRef.current = newVal;
    onChange?.(newVal);

    setTimeout(() => {
      setAnimatingValue(null);
      setDirection(null);
    }, 400);
  };

  const isDecreaseDisabled = renderValue <= min;
  const handleDecrement = () => {
    if (valueRef.current <= min) {
      triggerError();
      return;
    }
    triggerAnimation(formatValue(valueRef.current - multiplier), 'decrease');
  };

  const isIncreaseDisabled = renderValue >= max;
  const handleIncrement = () => {
    if (valueRef.current >= max) {
      triggerError();
      return;
    }
    triggerAnimation(formatValue(valueRef.current + multiplier), 'increase');
  };

  const stopAutoRepeat = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    if (intervalRef.current) clearInterval(intervalRef.current);
  };

  const startAutoRepeat = (action: 'increase' | 'decrease') => {
    // First action
    if (action === 'increase') handleIncrement();
    else handleDecrement();

    // Start timer
    timerRef.current = setTimeout(() => {
      intervalRef.current = setInterval(() => {
        if (action === 'increase') handleIncrement();
        else handleDecrement();
      }, 400);
    }, 600);
  };

  useEffect(() => {
    return () => stopAutoRepeat();
  }, []);

  const isHorizontal = variant === 'horizontal';

  return (
    <div className="flex flex-col gap-1 w-full">
      {label && <label className="text-sm font-semibold text-gray-700">{label}</label>}
      <div
        className={`flex ${isHorizontal ? 'flex-row' : 'flex-col-reverse'} items-center bg-gray-50 border-2 rounded-2xl overflow-hidden w-fit transition-colors
          ${errorPulse ? 'animate-shake-error' : 'border-gray-200'}
        `}
      >
        <button
          type="button"
          onMouseDown={() => startAutoRepeat('decrease')}
          onMouseUp={stopAutoRepeat}
          onMouseLeave={stopAutoRepeat}
          onTouchStart={(e) => { e.preventDefault(); startAutoRepeat('decrease'); }}
          onTouchEnd={stopAutoRepeat}
          aria-disabled={isDecreaseDisabled}
          className={`flex items-center justify-center p-3 text-white bg-page-yellow transition-all relative z-10 select-none
            ${isDecreaseDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:brightness-110 active:brightness-90'}
            ${isHorizontal ? 'border-r-2 border-gray-200' : 'border-t-2 border-gray-200'}
          `}
        >
          <MinusIcon className="w-5 h-5" />
        </button>

        <div className={`relative flex items-center justify-center font-bold text-gray-800 overflow-hidden ${isHorizontal ? 'w-16 h-12' : 'w-12 h-12'}`}>

          {/* exit value */}
          {animatingValue !== null && (
            <div className={`absolute inset-0 flex items-center justify-center
              ${direction === 'increase'
                ? isHorizontal ? 'animate-slide-out-left' : 'animate-slide-out-up'
                : isHorizontal ? 'animate-slide-out-right' : 'animate-slide-out-down'
              }
            `}>
              {animatingValue}
            </div>
          )}

          {/* new value */}
          <div
            key={renderValue}
            className={`absolute inset-0 flex items-center justify-center
              ${animatingValue !== null ? (
                direction === 'increase'
                ? isHorizontal ? 'animate-slide-in-right' : 'animate-slide-in-down'
                : isHorizontal ? 'animate-slide-in-left' : 'animate-slide-in-up'
              ) : ''}
            `}
          >
            {renderValue}
          </div>
        </div>

        <button
          type="button"
          onMouseDown={() => startAutoRepeat('increase')}
          onMouseUp={stopAutoRepeat}
          onMouseLeave={stopAutoRepeat}
          onTouchStart={(e) => { e.preventDefault(); startAutoRepeat('increase'); }}
          onTouchEnd={stopAutoRepeat}
          aria-disabled={isIncreaseDisabled}
          className={`flex items-center justify-center p-3 text-white bg-page-blue transition-all relative z-10 select-none
            ${isIncreaseDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:brightness-110 active:brightness-90'}
            ${isHorizontal ? 'border-l-2 border-gray-200' : 'border-b-2 border-gray-200'}
          `}
        >
          <PlusIcon className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
};
