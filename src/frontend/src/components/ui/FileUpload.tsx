import { useEffect } from 'react';
import { CloseButton } from './ExitButton';
import { useImageControls } from '../../hooks/useImageControls';
import { useFileUpload } from '../../hooks/useFileUpload';
import { ImageControls } from '../media/ImageControls';
import { ImagePagination } from '../media/ImagePagination';
import PhotoIcon from '../../assets/svg/icons/icon_photo.svg?react';

interface FileUploadProps {
  label?: string;
  maxFiles?: number;
  className?: string;
  width?: string;
  height?: string;
  onFilesChange?: (files: File[]) => void;
}

export const FileUpload = ({
  maxFiles = 3,
  label = `ARRASTRA MÁXIMO ${maxFiles} IMÁGENES`,
  className = '',
  width = 'w-full',
  height = 'h-64',
  onFilesChange,
}: FileUploadProps) => {
  const {
    files,
    isDragging,
    inputRef,
    handleFiles,
    handleDrop,
    handleDragOver,
    handleDragLeave,
    handleRemoveImage,
  } = useFileUpload({ maxFiles, onFilesChange });

  const { currentIndex, next, prev, goTo, pause, resume } = useImageControls({
    totalItems: files.length,
    autoPlay: false,
  });

  useEffect(() => {
    if (currentIndex >= files.length && files.length > 0) {
      goTo(files.length - 1);
    }
  }, [files.length, currentIndex, goTo]);

  return (
    <div
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onMouseEnter={pause}
      onMouseLeave={resume}
      className={`relative rounded-[18px] overflow-hidden select-none transition-colors flex-shrink-0 min-w-[240px] min-h-[160px] ${width} ${height} ${
        files.length === 0
          ? isDragging
            ? 'bg-gray-300 border-2 border-dashed border-page-blue text-page-blue cursor-pointer'
            : 'bg-[#dfdfdf] text-[#aaaaaa] hover:bg-gray-300 cursor-pointer group'
          : 'bg-black shadow-md'
      } ${className}`}
      onClick={() => {
        if (files.length === 0) inputRef.current?.click();
      }}
    >
      <input
        ref={inputRef}
        type="file"
        multiple={maxFiles > 1}
        accept="image/*"
        className="hidden"
        onChange={(e) => handleFiles(e.target.files)}
      />

      {files.length === 0 ? (
        <div className="w-full h-full flex flex-col items-center justify-center gap-3 p-4">
          <PhotoIcon className={`text-current w-20 h-20 transition-transform duration-300 ${isDragging ? 'scale-110' : 'group-hover:scale-105'}`} />
          <span className="text-base font-medium px-4 text-center">
            {isDragging ? '¡SUELTA LAS IMÁGENES AQUÍ!' : label}
          </span>
        </div>
      ) : (
        <div className="relative w-full h-full overflow-hidden group">
          <div
            className="absolute inset-0 flex transition-transform duration-500 ease-out"
            style={{ transform: `translateX(-${currentIndex * 100}%)` }}
          >
            {files.map((file, idx) => (
              <div key={`${file.name}-${idx}`} className="min-w-full h-full flex-shrink-0">
                <img
                  src={URL.createObjectURL(file)}
                  alt={`Preview ${idx + 1}`}
                  className="w-full h-full object-cover block select-none pointer-events-none"
                />
              </div>
            ))}
          </div>

          <CloseButton
            onClick={(e) => {
              e.stopPropagation();
              handleRemoveImage(currentIndex);
            }}
            className="absolute top-3 right-3"
          />

          {files.length < maxFiles && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                inputRef.current?.click();
              }}
              className="absolute top-3 left-3 bg-black/60 hover:bg-black/80 text-white text-xs font-semibold px-2.5 py-1.5 rounded-full backdrop-blur transition-all active:scale-95 z-20"
            >
              + Añadir ({files.length}/{maxFiles})
            </button>
          )}

          {files.length > 1 && (
            <>
              <ImageControls
                onPrev={(e) => {
                  e.stopPropagation();
                  prev();
                }}
                onNext={(e) => {
                  e.stopPropagation();
                  next();
                }}
              />
              <ImagePagination
                total={files.length}
                currentIndex={currentIndex}
                onSelect={goTo}
              />
            </>
          )}
        </div>
      )}
    </div>
  );
};
