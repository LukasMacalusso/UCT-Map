import { useState, useEffect } from 'react';
import { Button } from './Button';
import type { PageColor } from '../../constants/colors';

export interface ActionOption {
  label: string;
  color?: PageColor;
  onClick: () => void;
}

export interface TimedActionCardProps {
  title?: string;
  description?: string;
  initialDurationMs: number;
  options: ActionOption[];
}

export const TimedActionCard = ({
  title = 'Action Required',
  description = 'Please wait until the timer completes before selecting an option.',
  initialDurationMs,
  options
}: TimedActionCardProps) => {
  const [isActive, setIsActive] = useState(false);
  const [progress, setProgress] = useState(100);
  const [prevDuration, setPrevDuration] = useState(initialDurationMs);

  if (initialDurationMs !== prevDuration) {
    setPrevDuration(initialDurationMs);
    setIsActive(false);
    setProgress(100);
  }

  useEffect(() => {
    const startTime = Date.now();
    const endTime = startTime + initialDurationMs;

    const intervalId = setInterval(() => {
      const now = Date.now();
      const remaining = Math.max(0, endTime - now);
      const percentage = (remaining / initialDurationMs) * 100;
      
      setProgress(percentage);

      if (remaining <= 0) {
        setIsActive(true);
        clearInterval(intervalId);
      }
    }, 16); // ~60fps for smooth visual update without CSS transitions if needed, or we can use CSS.
    // Actually, relying on CSS transition is smoother. We will set width to 0 immediately in a timeout.

    return () => clearInterval(intervalId);
  }, [initialDurationMs]);

  return (
    <div className="bg-white rounded-[24px] p-6 shadow-md relative overflow-hidden max-w-lg w-full flex flex-col gap-6 group">
      
      {/* Active UCT Border Mask */}
      <div
        className={`absolute inset-0 rounded-[24px] pointer-events-none p-[4px] z-20 transition-[clip-path] duration-500 ease-out bg-[linear-gradient(to_right,var(--color-page-blue)_50%,var(--color-page-yellow)_50%)] [clip-path:inset(-10px_-10px_-10px_-10px)]`}
        style={{
          WebkitMask: 'linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)',
          WebkitMaskComposite: 'xor',
          maskComposite: 'exclude'
        }}
      />
      
      {/* Fallback standard border behind the gradient one */}
      <div className="absolute inset-0 border border-gray-200 rounded-[24px] pointer-events-none z-10" />

      <div className="flex flex-col gap-2 text-center relative z-30">
        <h3 className="text-xl font-bold text-gray-800">{title}</h3>
        <p className="text-sm text-gray-500">{description}</p>
      </div>

      {/* Progress Bar Container */}
      <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden relative z-30 flex justify-center">
        {/* The shrinking bar from edges to center */}
        <div 
          className={`h-full transition-all ease-linear bg-[linear-gradient(to_right,var(--color-page-blue)_50%,var(--color-page-yellow)_50%)]`}
          style={{ 
            width: `${progress}%`,
            transitionDuration: '16ms' 
          }}
        />
      </div>

      {/* Action Buttons */}
      <div className="flex flex-wrap justify-center gap-4 relative z-30">
        {options.map((opt, idx) => (
          <Button 
            key={idx} 
            color={opt.color || 'blue'}
            disabled={!isActive}
            onClick={opt.onClick}
          >
            {opt.label}
          </Button>
        ))}
      </div>

    </div>
  );
};
