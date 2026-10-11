import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ImageGallery } from './ImageGallery';

describe('ImageGallery', () => {
  it('renders fallback when images array is empty', () => {
    render(<ImageGallery images={[]} />);
    expect(screen.getByText('No hay imágenes disponibles')).toBeInTheDocument();
  });
});
