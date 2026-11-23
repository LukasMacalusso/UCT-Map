
interface ImagePaginationProps {
  total: number;
  currentIndex: number;
  onSelect: (index: number) => void;
  className?: string;
}

export const ImagePagination = ({
  total,
  currentIndex,
  onSelect,
  className = '',
}: ImagePaginationProps) => {
  if (total <= 1) return null;

  return (
    <div className={`absolute bottom-3 left-1/2 -translate-x-1/2 bg-white/80 backdrop-blur rounded-full px-3 py-1 flex gap-2 items-center shadow-lg z-20 ${className}`}>
      {Array.from({ length: total }).map((_, idx) => (
        <button
          key={idx}
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            onSelect(idx);
          }}
          className={`w-3 h-3 rounded-full transition-all ${
            idx === currentIndex ? 'bg-black scale-125' : 'bg-gray-400 hover:bg-gray-500'
          }`}
          aria-label={`Ir a la diapositiva ${idx + 1}`}
        />
      ))}
    </div>
  );
};
