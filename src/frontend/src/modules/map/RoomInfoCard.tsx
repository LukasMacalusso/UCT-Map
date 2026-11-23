import UserIcon from '../../assets/svg/icons/icon_users.svg?react';
import DoorIcon from '../../assets/svg/icons/icon_door.svg?react';


interface RoomInfoCardProps {
  title: string;
  type: string;
  capacity: number | string;
  icon?: React.ReactNode;
  className?: string;
}

export const RoomInfoCard = ({
  title,
  type,
  capacity,
  icon,
  className = '',
}: RoomInfoCardProps) => {
  return (
    <div className={`bg-[#e0e0e0] rounded-2xl px-5 py-4 flex items-center justify-between gap-6 shadow-sm w-full max-w-lg ${className}`}>
      <div className="flex items-center gap-4">
        <div className="flex-shrink-0 flex items-center justify-center">
          {icon || <DoorIcon className="w-10 h-10 text-gray-900" />}
        </div>
        <div className="flex flex-col justify-center">
          <h3 className="text-xl font-bold text-gray-800 tracking-wide uppercase leading-tight">
            {title}
          </h3>
          <p className="text-base font-semibold text-gray-700 leading-tight">
            {type}
          </p>
        </div>
      </div>

      <div className="flex-shrink-0 bg-gray-400/60 px-3.5 py-1.5 rounded-xl flex items-center gap-2 text-gray-800 font-bold text-base">
        <UserIcon className="w-5 h-5 text-gray-900" />
        <span>{capacity}</span>
      </div>
    </div>
  );
};
