
interface ImageControlsProps {
  onPrev: (e: React.MouseEvent) => void;
  onNext: (e: React.MouseEvent) => void;
}

export const ImageControls = ({ onPrev, onNext }: ImageControlsProps) => {
  return (
    <>
      <button
        type="button"
        onClick={onPrev}
        className="absolute left-2 top-1/2 -translate-y-1/2 text-white/90 hover:text-white hover:scale-110 transition-all duration-500 ease-out active:duration-75 active:-translate-x-1.5 active:scale-95 drop-shadow-md z-20"
        aria-label="Anterior"
      >

        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="64"
          height="64"
          viewBox="0 0 24 24"
          fill="currentColor"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinejoin="round"
        >
          <polygon points="16,5 8,12 16,19" />
        </svg>
      </button>

      <button
        type="button"
        onClick={onNext}
        className="absolute right-2 top-1/2 -translate-y-1/2 text-white/90 hover:text-white hover:scale-110 transition-all duration-500 ease-out active:duration-75 active:translate-x-1.5 active:scale-95 drop-shadow-md z-20"
        aria-label="Siguiente"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="64"
          height="64"
          viewBox="0 0 24 24"
          fill="currentColor"
          stroke="currentColor"
          strokeWidth="1.5"
          strokeLinejoin="round"
        >
          <polygon points="8,5 16,12 8,19" />
        </svg>
      </button>
    </>
  );
};
