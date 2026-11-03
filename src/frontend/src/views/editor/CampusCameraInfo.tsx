import type { CampusCamera } from '../../modules/map/CampusMapCanvas';

const format = (value: number, digits: number) => value.toFixed(digits);

export const CampusCameraInfo = ({ camera }: { camera: CampusCamera }) => {
  return (
    <div className="flex flex-col gap-2 pt-1">
      <div className="grid grid-cols-2 gap-2 text-xs">
        <div className="bg-white p-2.5 rounded-xl border border-gray-100 flex flex-col gap-0.5 shadow-xs">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Latitud</span>
          <span className="font-mono text-xs font-bold text-gray-800">{format(camera.latitude, 5)}</span>
        </div>

        <div className="bg-white p-2.5 rounded-xl border border-gray-100 flex flex-col gap-0.5 shadow-xs">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Longitud</span>
          <span className="font-mono text-xs font-bold text-gray-800">{format(camera.longitude, 5)}</span>
        </div>

        <div className="bg-white p-2.5 rounded-xl border border-gray-100 flex flex-col gap-0.5 shadow-xs">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Zoom</span>
          <span className="font-mono text-xs font-bold text-page-blue">{format(camera.zoom, 2)}x</span>
        </div>

        <div className="bg-white p-2.5 rounded-xl border border-gray-100 flex flex-col gap-0.5 shadow-xs">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Inclinación (Pitch)</span>
          <span className="font-mono text-xs font-bold text-gray-800">{format(camera.pitch, 1)}°</span>
        </div>

        <div className="col-span-2 bg-white p-2.5 rounded-xl border border-gray-100 flex items-center justify-between shadow-xs">
          <span className="text-[10px] font-bold text-gray-400 uppercase tracking-wider">Orientación (Bearing)</span>
          <span className="font-mono text-xs font-bold text-gray-800">{format(camera.bearing, 1)}°</span>
        </div>
      </div>
    </div>
  );
};
