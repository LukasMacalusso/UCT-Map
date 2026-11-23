
type IconButtonSize = 'sm' | 'md' | 'lg';

interface CloseButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'solid' | 'ghost';
  size?: IconButtonSize;
}

export const CloseButton = ({
  variant = 'solid',
  size = 'md',
  className = '',
  ...props
}: CloseButtonProps) => {
  const sizeClasses: Record<IconButtonSize, { btn: string; icon: number }> = {
    sm: { btn: 'p-1', icon: 14 },
    md: { btn: 'p-1.5', icon: 18 },
    lg: { btn: 'p-2', icon: 22 },
  };

  const currentSize = sizeClasses[size];

  const variantClasses = {
    solid: 'bg-red-500/80 hover:bg-red-600 text-white rounded-full backdrop-blur shadow-md',
    ghost: 'bg-transparent text-gray-400 hover:text-red-500 rounded-full',
  };

  return (
    <button
      type="button"
      className={`inline-flex items-center justify-center transition-all duration-200 hover:scale-110 active:scale-95 z-20 ${currentSize.btn} ${variantClasses[variant]} ${className}`.trim()}
      aria-label="Cerrar"
      {...props}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width={currentSize.icon}
        height={currentSize.icon}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M18 6 6 18" />
        <path d="m6 6 12 12" />
      </svg>
    </button>
  );
};
