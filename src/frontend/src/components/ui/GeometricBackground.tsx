import React from 'react';

interface GeometricBackgroundProps {
  className?: string;
  variant?: 'dark' | 'blue';
}

export const GeometricBackground: React.FC<GeometricBackgroundProps> = ({
  className = '',
}) => {
  return (
    <div className={`relative w-full h-full overflow-hidden select-none pointer-events-none ${className}`}>
      <svg
        viewBox="0 0 1920 1080"
        preserveAspectRatio="xMidYMid slice"
        className="w-full h-full block"
        xmlns="http://www.w3.org/2000/svg"
        shapeRendering="geometricPrecision"
      >
        {/* Layer 0: Base plana gris */}
        <rect width="1920" height="1080" fill="#222222" />

        {/* Layer 1: Corte 1 - pendiente ~ -57.1° */}
        <path
          d="M 420 0 L 1920 0 L 1920 1080 L 0 1080 L 0 650 Z"
          fill="#292929"
        />

        {/* Layer 2: Corte 2 - pendiente ~ -52.8° */}
        <path
          d="M 980 0 L 1920 0 L 1920 1080 L 160 1080 Z"
          fill="#222222"
        />

        {/* Layer 3: Corte 3 - pendiente ~ -46.1° */}
        <path
          d="M 1620 0 L 1920 0 L 1920 1080 L 580 1080 Z"
          fill="#2c2c2c"
        />

        {/* Layer 4: Corte 4 - pendiente ~ -51.0° */}
        <path
          d="M 1920 240 L 1920 1080 L 1240 1080 Z"
          fill="#242424"
        />

        {/* Layer 5: Corte 5 - pendiente ~ -56.3° */}
        <path
          d="M 1920 660 L 1920 1080 L 1640 1080 Z"
          fill="#2e2e2e"
        />

        {/* Líneas de división nítidas y sólidas (sin sombreados) */}
        <line x1="420" y1="0" x2="0" y2="650" stroke="#383838" strokeWidth="1.5" />
        <line x1="980" y1="0" x2="160" y2="1080" stroke="#383838" strokeWidth="1.5" />
        <line x1="1620" y1="0" x2="580" y2="1080" stroke="#383838" strokeWidth="1.5" />
        <line x1="1920" y1="240" x2="1240" y2="1080" stroke="#383838" strokeWidth="1.5" />
        <line x1="1920" y1="660" x2="1640" y2="1080" stroke="#383838" strokeWidth="1.5" />
      </svg>
    </div>
  );
};
