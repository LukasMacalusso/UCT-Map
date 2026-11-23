
export interface HeatmapSpotProps {
  x: string | number;
  y: string | number;
  intensity: number;
  baseSize?: number;
}

export const HeatmapSpot = ({ x, y, intensity, baseSize = 120 }: HeatmapSpotProps) => {
  // Normalize intensity between 0 and 100
  const normalizedIntensity = Math.min(Math.max(intensity, 0), 100);

  // Determine color
  let rgb = '255, 204, 0';
  if (normalizedIntensity > 66) {
    rgb = '255, 59, 48';
  } else if (normalizedIntensity > 33) {
    rgb = '255, 149, 0';
  }

  // Size scales with intensity
  const scale = 0.5 + (normalizedIntensity / 100);
  const size = baseSize * scale;

  return (
    <div
      className="absolute rounded-full pointer-events-none animate-pulse"
      style={{
        left: x,
        top: y,
        width: size,
        height: size,
        transform: 'translate(-50%, -50%)',
        background: `radial-gradient(circle, rgba(${rgb}, 0.8) 0%, rgba(${rgb}, 0.4) 30%, rgba(${rgb}, 0) 70%)`,
        zIndex: 5
      }}
    />
  );
};
