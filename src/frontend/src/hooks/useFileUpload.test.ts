import { describe, it, expect, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useFileUpload } from './useFileUpload';

describe('useFileUpload hook', () => {
  it('adds and limits valid image files', () => {
    const onFilesChange = vi.fn();
    const { result } = renderHook(() => useFileUpload({ maxFiles: 2, onFilesChange }));

    const file1 = new File(['1'], 'img1.png', { type: 'image/png' });
    const file2 = new File(['2'], 'doc.pdf', { type: 'application/pdf' }); // invalid
    const file3 = new File(['3'], 'img3.jpg', { type: 'image/jpeg' });
    const file4 = new File(['4'], 'img4.jpg', { type: 'image/jpeg' });

    const fileList = [file1, file2, file3, file4] as unknown as FileList;

    act(() => {
      result.current.handleFiles(fileList);
    });

    expect(result.current.files.length).toBe(2);
    expect(result.current.files[0].name).toBe('img1.png');
    expect(result.current.files[1].name).toBe('img3.jpg');
    expect(onFilesChange).toHaveBeenCalledWith(result.current.files);
  });

  it('removes image by index', () => {
    const onFilesChange = vi.fn();
    const { result } = renderHook(() => useFileUpload({ maxFiles: 5, onFilesChange }));

    const file1 = new File(['1'], 'img1.png', { type: 'image/png' });
    const file2 = new File(['2'], 'img2.png', { type: 'image/png' });

    act(() => {
      result.current.handleFiles([file1, file2] as unknown as FileList);
    });

    expect(result.current.files.length).toBe(2);

    act(() => {
      result.current.handleRemoveImage(0);
    });

    expect(result.current.files.length).toBe(1);
    expect(result.current.files[0].name).toBe('img2.png');
  });

  it('handles drag events', () => {
    const { result } = renderHook(() => useFileUpload({ maxFiles: 5 }));

    const preventDefault = vi.fn();

    act(() => {
      result.current.handleDragOver({ preventDefault } as unknown as React.DragEvent<HTMLDivElement>);
    });
    expect(result.current.isDragging).toBe(true);

    act(() => {
      result.current.handleDragLeave();
    });
    expect(result.current.isDragging).toBe(false);

    act(() => {
      result.current.handleDrop({
        preventDefault,
        dataTransfer: { files: [] as unknown as FileList },
      } as unknown as React.DragEvent<HTMLDivElement>);
    });
    expect(result.current.isDragging).toBe(false);
  });
});
