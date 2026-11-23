import { Avatar, type AvatarSize } from '../media/Avatar';

export type UserActionInfoSize = 'sm' | 'md' | 'lg';

interface UserActionInfoProps {
  title: string;
  subtitle: string;
  avatarSrc?: string | null;
  size?: UserActionInfoSize;
  className?: string;
}

export const UserActionInfo = ({
  title,
  subtitle,
  avatarSrc,
  size = 'md',
  className = '',
}: UserActionInfoProps) => {
  const avatarSizeMap: Record<UserActionInfoSize, AvatarSize> = {
    sm: 'sm',
    md: 'md',
    lg: 'lg',
  };

  const titleSizeMap: Record<UserActionInfoSize, string> = {
    sm: 'text-xs font-semibold',
    md: 'text-sm font-semibold',
    lg: 'text-base font-semibold',
  };

  const subtitleSizeMap: Record<UserActionInfoSize, string> = {
    sm: 'text-[11px] text-gray-400 font-normal',
    md: 'text-xs text-gray-500 font-normal',
    lg: 'text-sm text-gray-500 font-normal',
  };

  return (
    <div className={`flex items-center gap-3 bg-white p-1.5 rounded-xl ${className}`}>
      <Avatar src={avatarSrc} size={avatarSizeMap[size]} />
      <div className="flex flex-col justify-center min-w-0">
        <h3 className={`${titleSizeMap[size]} leading-snug text-page-dark truncate`}>{title}</h3>
        <p className={`${subtitleSizeMap[size]} leading-tight`}>{subtitle}</p>
      </div>
    </div>
  );
};
