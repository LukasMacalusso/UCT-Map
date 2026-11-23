import { useState, useRef, type DragEvent } from 'react';

interface UseFileUploadProps {
  maxFiles: number;
  onFilesChange?: (files: File[]) => void;
}

export const useFileUpload = ({ maxFiles, onFilesChange }: UseFileUploadProps) => {
  const [files, setFiles] = useState<File[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleFiles = (incomingFiles: FileList | null) => {
    if (!incomingFiles) return;

    const validNewFiles = Array.from(incomingFiles).filter((file) =>
      file.type.startsWith('image/')
    );

    setFiles((prevFiles) => {
      const combined = [...prevFiles, ...validNewFiles].slice(0, maxFiles);
      if (onFilesChange) onFilesChange(combined);
      return combined;
    });
  };

  const handleDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(false);
    handleFiles(e.dataTransfer.files);
  };

  const handleDragOver = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleRemoveImage = (indexToRemove: number) => {
    setFiles((prevFiles) => {
      const updated = prevFiles.filter((_, idx) => idx !== indexToRemove);
      if (onFilesChange) onFilesChange(updated);
      return updated;
    });
  };

  return {
    files,
    isDragging,
    inputRef,
    handleFiles,
    handleDrop,
    handleDragOver,
    handleDragLeave,
    handleRemoveImage,
  };
};
