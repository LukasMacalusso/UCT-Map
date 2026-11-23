import { describe, it, expect } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LoginView } from './LoginView';
import { renderWithQueryClient } from '../test/renderWithQueryClient';

describe('LoginView', () => {
  it('renders login view with forms and switches between login and register', () => {
    renderWithQueryClient(
      <MemoryRouter>
        <LoginView />
      </MemoryRouter>,
    );

    expect(screen.getByRole('heading', { name: /iniciar sesión/i })).toBeInTheDocument();

    const switchBtn = screen.getByRole('button', { name: 'Regístrate' });
    fireEvent.click(switchBtn);

    expect(screen.getByRole('heading', { name: /crear cuenta/i })).toBeInTheDocument();

    const guestBtn = screen.getByRole('button', { name: /continuar como invitado/i });
    fireEvent.click(guestBtn);
  });
});
