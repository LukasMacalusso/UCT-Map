import { type PageColor, bgPageColors } from '../../constants/colors';
import { CloseButton } from '../ui/ExitButton';

export type PanelSize = 'sm' | 'md' | 'lg' | 'xl' | 'auto';

const sizeMap: Record<PanelSize, string> = {
  sm: 'max-w-md w-full',
  md: 'max-w-2xl w-full',
  lg: 'max-w-4xl w-full',
  xl: 'max-w-5xl w-full',
  auto: 'w-max',
};

interface PanelProps {
  children: React.ReactNode;
  color?: PageColor;
  withUctBorder?: boolean;
  size?: PanelSize;
  outerClassName?: string;
  innerClassName?: string;
  onClose?: () => void;
}

export const Panel = ({
  children,
  color = 'white',
  withUctBorder = false,
  size = 'auto',
  outerClassName = '',
  innerClassName = 'p-6 flex flex-col relative',
  onClose
}: PanelProps) => {
  const sizeClass = sizeMap[size];

  const bgColorClass = color === 'gray'
    ? "bg-page-gray-light border border-gray-200"
    : bgPageColors[color];

  const renderCloseButton = () => {
      if (!onClose) return null;
      return (
        <div className="flex justify-end w-full mb-2">
          <CloseButton
            variant="ghost"
            size="lg"
            onClick={onClose}
          />
        </div>
      );
    };
  if (withUctBorder) {
    return (
      <div
        className={`bg-gradient-to-b from-page-blue from-50% to-page-yellow to-50% p-1.5 shadow-md h-max rounded-3xl ${sizeClass} ${outerClassName}`}
      >
        <div className={`${bgColorClass} w-full h-full rounded-2xl ${innerClassName}`}>
          {renderCloseButton()}
          {children}
        </div>
      </div>
    );
  }

  return (
    <div className={`${bgColorClass} shadow-sm h-max relative rounded-3xl ${sizeClass} ${outerClassName} ${innerClassName}`}>
      {renderCloseButton()}
      {children}
    </div>
  );
};
