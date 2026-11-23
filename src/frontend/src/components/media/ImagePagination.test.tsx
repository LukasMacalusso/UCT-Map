import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ImagePagination } from './ImagePagination';

describe('ImagePagination', () => {
  it('renders buttons for each slide when total > 1', () => {
    render(<ImagePagination total={3} currentIndex={0} onSelect={() => {}} />);
    const buttons = screen.getAllByRole('button');
    expect(buttons).toHaveLength(3);
  });
});
