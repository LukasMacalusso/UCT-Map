import { useState, useEffect } from 'react';

export interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  color?: string;
  className?: string;
  text?: string;
  texts?: string[];
  variant?: 'classic' | 'dark' | 'light';
  hideText?: boolean;
}

export const LoadingSpinner = ({ 
  size = 'md', 
  color = 'text-page-blue', 
  className = '',
  text,
  texts,
  variant = 'classic',
  hideText = false
}: LoadingSpinnerProps) => {
  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-12 h-12',
    lg: 'w-20 h-20',
    xl: 'w-32 h-32'
  };

  const hasMultipleTexts = Array.isArray(texts) && texts.length > 0;
  const [currentText, setCurrentText] = useState(() => hasMultipleTexts ? texts[0] : text);
  const [isFading, setIsFading] = useState(false);
  const textsKey = texts ? texts.join('||') : '';

  useEffect(() => {
    if (!hasMultipleTexts || !texts || texts.length === 0) return;

    const interval = setInterval(() => {
      setIsFading(true);
      
      setTimeout(() => {
        setCurrentText((prevText) => {
          let nextIndex;
          do {
            nextIndex = Math.floor(Math.random() * texts.length);
          } while (texts[nextIndex] === prevText && texts.length > 1);
          return texts[nextIndex];
        });
        setIsFading(false);
      }, 700);

    }, 3500); 

    return () => clearInterval(interval);
  }, [textsKey, hasMultipleTexts, texts]);

  const outerArc1Class = variant === 'dark' ? 'text-black opacity-90' : variant === 'light' ? 'text-white opacity-90' : 'opacity-80';
  const outerArc2Class = variant === 'dark' ? 'text-black opacity-40' : variant === 'light' ? 'text-white opacity-40' : 'text-page-yellow opacity-80';
  const innerTreeClass = variant === 'dark' ? 'text-black' : variant === 'light' ? 'text-white' : 'text-gray-400';
  const textClass = variant === 'dark' ? 'text-black' : variant === 'light' ? 'text-white' : 'text-gray-500';

  return (
    <div className={`flex flex-col items-center justify-center gap-4 ${className}`}>
      <div className={`relative flex items-center justify-center ${sizeClasses[size]} ${variant === 'classic' ? color : ''}`}>
        <div className="absolute inset-0 w-full h-full animate-[spin_4s_linear_infinite]">
          <svg
            className="w-full h-full animate-spin-expo"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
          >
            <circle cx="12" cy="12" r="11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" style={{ strokeDasharray: '18 52' }} className={outerArc1Class} />
            <circle cx="12" cy="12" r="11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" style={{ strokeDasharray: '18 52', strokeDashoffset: '34.5' }} className={outerArc2Class} />
          </svg>
        </div>

        <svg
          className={`absolute inset-0 w-full h-full p-0.5 ${innerTreeClass}`}
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
        >
          <defs>
            <clipPath id="uct-tree-clip">
              <circle cx="12" cy="12" r="10.8" />
            </clipPath>
          </defs>
          <g clipPath="url(#uct-tree-clip)" style={{ animation: 'uct-group-fade 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' }}>
            <path 
              d="M 12 22.8 L 12 1.2" 
              style={{ 
                strokeDasharray: 21.6, 
                animation: 'uct-draw-line 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' 
              }} 
            />
            <path 
              d="M 12 9.5 L 20.7 9.5" 
              strokeLinecap="butt"
              style={{ '--len': '8.7', strokeDasharray: '8.7', animation: 'uct-sprout-2 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' } as React.CSSProperties} 
            />
            <path 
              d="M 12 5.5 A 4.3 4.3 0 0 1 7.7 1.2" 
              style={{ '--len': '6.8', strokeDasharray: '6.8', animation: 'uct-sprout-1 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' } as React.CSSProperties} 
            />
            <path 
              d="M 12 9.5 A 8.3 8.3 0 0 1 3.7 1.2" 
              style={{ '--len': '13.0', strokeDasharray: '13.0', animation: 'uct-sprout-2 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' } as React.CSSProperties} 
            />
            <path 
              d="M 12 13.5 A 12.3 12.3 0 0 1 -0.3 1.2" 
              style={{ '--len': '19.3', strokeDasharray: '19.3', animation: 'uct-sprout-3 2.8s infinite cubic-bezier(0.16, 1, 0.3, 1)' } as React.CSSProperties} 
            />
          </g>
        </svg>
      </div>
      
      {!hideText && (currentText || text) && (
        <p 
          className={`${textClass} font-medium transition-all duration-700 ease-in-out text-center max-w-[250px] leading-snug ${isFading ? 'opacity-0 translate-y-3' : 'opacity-100 translate-y-0'} ${!hasMultipleTexts ? 'animate-pulse' : ''}`}
        >
          {hasMultipleTexts ? currentText : text}
        </p>
      )}
    </div>
  );
};
