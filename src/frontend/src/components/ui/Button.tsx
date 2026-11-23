import { type PageColor, bgPageColors, textPageColors, borderPageColors, hoverBgPageColors, solidButtonConfig } from '../../constants/colors';

type ButtonSize = 'sm' | 'md' | 'lg';
type ButtonWidth = 'sm' | 'md' | 'lg';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'solid' | 'outline' | 'ghost';
  color?: PageColor;
  size?: ButtonSize;
  width?: ButtonWidth;
}

export const Button = ({
  variant = 'solid',
  color = 'blue',
  size = 'md',
  width = "sm",
  disabled = false,
  className = '',
  children,
  ...props
}: ButtonProps) => {

  const sizeClasses: Record<ButtonSize, string> = {
    sm: "px-3.5 py-1.5 text-xs font-semibold",
    md: "px-5 py-2 text-sm font-semibold",
    lg: "px-7 py-2.5 text-base font-semibold tracking-wide"
  };

  const widthClasses: Record<ButtonWidth, string> = {
    sm: "w-28",
    md: "w-44",
    lg: "w-56"
  };

  const resolvedWidth = width ? widthClasses[width] : '';
  const disabledClasses = disabled ? "opacity-50 pointer-events-none cursor-not-allowed" : "";
  const baseClasses = `${sizeClasses[size]} ${resolvedWidth} rounded-full font-medium transition-all duration-200 active:scale-95 ${disabledClasses}`;

  let variantClasses = "";
  if (variant === 'solid') {
    const config = solidButtonConfig[color];
    variantClasses = `${bgPageColors[color]} ${config.text} ${config.hover} shadow-sm border-[3px] border-transparent`;
  } else if (variant === 'outline') {
    variantClasses = `bg-transparent border-[3px] ${textPageColors[color]} ${borderPageColors[color]} ${hoverBgPageColors[color]}`;
  } else if (variant === 'ghost') {
    variantClasses = `bg-transparent ${textPageColors[color]} ${hoverBgPageColors[color]}`;
  }

  return (
    <button
      disabled={disabled}
      className={`${baseClasses} ${variantClasses} ${className}`.trim()}
      {...props}
    >
      {children}
    </button>
  );
};
