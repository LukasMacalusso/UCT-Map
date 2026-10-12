import { useState } from 'react';

export type AvatarSize = 'sm' | 'md' | 'lg' | 'xl';

const sizeClasses: Record<AvatarSize, string> = {
  sm: 'w-8 h-8 p-0.5',
  md: 'w-12 h-12 p-1',
  lg: 'w-20 h-20 p-1.5',
  xl: 'w-28 h-28 p-1.5',
};

interface AvatarProps {
  src?: string | null;
  alt?: string;
  size?: AvatarSize;
  className?: string;
}

export const Avatar = ({ src, alt = 'User Avatar', size, className = '' }: AvatarProps) => {
  const [hasError, setHasError] = useState(false);
  const sizeClass = size ? sizeClasses[size] : (className.includes('w-') ? '' : 'w-20 h-20 p-1.5');

  return (
    <div className={`rounded-full bg-gradient-to-b from-page-yellow from-50% to-page-blue to-50% shadow-md flex-shrink-0 ${sizeClass} ${className}`}>
      <div className="w-full h-full rounded-full overflow-hidden bg-page-gray-light flex items-center justify-center">
        {src && !hasError ? (
          <img
            src={src} alt={alt}
            className="w-full h-full object-cover"
            onError={() => setHasError(true)}
          />
        ) : (
          <span className="text-gray-400 text-xs font-semibold">N/A</span>
        )}
      </div>
    </div>
  );
};
