import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ImageControls } from './ImageControls';

describe('ImageControls', () => {
  it('renders navigation buttons', () => {
    render(<ImageControls onPrev={() => {}} onNext={() => {}} />);
    expect(screen.getByRole('button', { name: 'Anterior' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Siguiente' })).toBeInTheDocument();
  });
});
