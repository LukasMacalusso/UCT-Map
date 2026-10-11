import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { PhotoFrame } from './PhotoFrame';

describe('PhotoFrame', () => {
  it('renders image when src is provided', () => {
    render(<PhotoFrame src="https://example.com/photo.jpg" alt="Campus Photo" />);
    const img = screen.getByRole('img');
    expect(img).toBeInTheDocument();
    expect(img).toHaveAttribute('src', 'https://example.com/photo.jpg');
    expect(img).toHaveAttribute('alt', 'Campus Photo');
  });
});
