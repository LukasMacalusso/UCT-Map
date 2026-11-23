import { type PageColor, bgPageColors, borderPageColors } from '../../constants/colors';

interface MapMarkerProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon?: React.ReactNode;
  color?: PageColor;
  isActive?: boolean;
  badge?: number | string;
  heatmapIntensity?: number;
}

export const MapMarker = ({
  icon,
  color = 'blue',
  isActive = false,
  badge,
  heatmapIntensity,
  className = '',
  ...props
}: MapMarkerProps) => {
  const showHeatmap = heatmapIntensity !== undefined && heatmapIntensity > 0;
  const clampedIntensity = Math.min(Math.max(heatmapIntensity ?? 0, 0), 100);
  const factor = clampedIntensity / 100;

  // Transición suave de color: de naranja suave (251, 146, 60) a rojo intenso (220, 38, 38)
  const r = Math.round(251 + factor * (220 - 251));
  const g = Math.round(146 + factor * (38 - 146));
  const b = Math.round(60 + factor * (38 - 60));
  const heatColor = `${r}, ${g}, ${b}`;

  // Radio dinámico exponencial: desde 70px (radio sutil) hasta 200px (expansión notoria)
  const diameter = Math.round(70 + Math.pow(factor, 1.3) * 130);

  // Parpadeo más rápido mientras más cantidad: de 2.2s (calmado) a 0.8s (urgente/rápido)
  const pulseDuration = (2.2 - factor * 1.4).toFixed(2);

  return (
    <div className="relative flex items-center justify-center">
      {/* Heatmap Aura */}
      {showHeatmap && (
        <div
          className="absolute rounded-full pointer-events-none animate-pulse -rotate-45"
          style={{
            width: `${diameter}px`,
            height: `${diameter}px`,
            animationDuration: `${pulseDuration}s`,
            background: `radial-gradient(circle, rgba(${heatColor}, 0.8) 0%, rgba(${heatColor}, 0.4) 40%, rgba(${heatColor}, 0) 70%)`,
            zIndex: 0,
          }}
        />
      )}

      <button
        type="button"
        className={`relative group w-14 h-14 rounded-full flex items-center justify-center text-white shadow-lg transition-transform duration-300 hover:-translate-y-2 hover:shadow-xl focus:outline-none rounded-br-none rotate-45 border-[3px] border-white ${bgPageColors[color]} ${className}`}
        style={{ zIndex: 10 }}
        {...props}
      >
        <div className={`absolute w-[100px] h-[100px] top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 -rotate-45 pointer-events-none flex items-center justify-center ${isActive ? '[clip-path:inset(0_0_0_0)]' : '[clip-path:inset(100%_0_0_0)]'} transition-[clip-path] duration-300 ease-out z-[-1]`}>
          <div className={`w-[68px] h-[68px] rotate-45 rounded-full rounded-br-none border-[3px] ${borderPageColors[color]} opacity-80`} />
        </div>

        <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center -rotate-45 shadow-inner z-10">
          <span className="text-page-dark flex items-center justify-center w-6 h-6">
            {icon}
          </span>
        </div>

        {/* Count Badge */}
        {badge !== undefined && (
          <div className="absolute -top-1.5 -right-1.5 bg-red-600 text-white text-[11px] font-black w-6 h-6 rounded-full flex items-center justify-center shadow-md border-2 border-white -rotate-45 z-20">
            {badge}
          </div>
        )}
      </button>
    </div>
  );
};
