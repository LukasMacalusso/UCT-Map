
interface SquareButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children?: React.ReactNode;
}

export const SquareButton = ({ className = '', children, ...props }: SquareButtonProps) => {
  return (
    <button
      className={`flex items-center justify-center w-14 h-14 rounded-2xl transition-all duration-200 shadow-sm active:scale-95 bg-page-white text-page-blue hover:bg-gray-50 active:bg-page-yellow active:text-page-white cursor-pointer ${className}`}
      {...props}
    >
      <span className="flex items-center justify-center w-8 h-8">
        {children}
      </span>
    </button>
  );
};
