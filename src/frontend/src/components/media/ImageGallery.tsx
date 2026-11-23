import { useImageControls } from '../../hooks/useImageControls';
import { ImageControls } from './ImageControls';
import { ImagePagination } from './ImagePagination';

interface ImageGalleryProps {
  images: string[];
  className?: string;
  width?: string;
  height?: string;
  autoPlayInterval?: number;
}

export const ImageGallery = ({
  images = [],
  className = '',
  width = 'w-full',
  height = 'h-64',
  autoPlayInterval = 2500,
}: ImageGalleryProps) => {

  const { currentIndex, isManualTransition, next, prev, goTo, pause, resume } =
    useImageControls({
      totalItems: images.length,
      autoPlayInterval,
    });

  if (!images || images.length === 0) {
    return (
      <div className={`bg-gray-200 rounded-[2rem] flex items-center justify-center flex-shrink-0 ${width} ${height} ${className}`}>
        <span className="text-gray-500 font-medium">No hay imágenes disponibles</span>
      </div>
    );
  }

  return (
    <div
      className={`relative overflow-hidden rounded-[2rem] shadow-md group flex-shrink-0 ${width} ${height} ${className}`}
      onMouseEnter={pause}
      onMouseLeave={resume}
    >
      <div
        className="absolute inset-0 flex transition-transform duration-500 ease-out"
        style={{
          transform: `translateX(-${currentIndex * 100}%)`,
          transition: isManualTransition
            ? 'transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)'
            : 'transform 0.8s cubic-bezier(0.87, 0, 0.13, 1)',
        }}
      >
        {images.map((src, index) => (
          <div key={index} className="min-w-full h-full flex-shrink-0">
            <img
              src={src}
              alt={`Imagen ${index + 1}`}
              className="w-full h-full object-cover block select-none pointer-events-none"
            />
          </div>
        ))}
      </div>

      {images.length > 1 && (
      <>
        <ImageControls onPrev={prev} onNext={next} />
        <ImagePagination
          total={images.length}
          currentIndex={currentIndex}
          onSelect={goTo}
        />
      </>
    )}
    </div>
  );
};
