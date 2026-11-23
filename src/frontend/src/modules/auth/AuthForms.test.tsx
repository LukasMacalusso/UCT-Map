import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LoginForm } from './LoginForm';
import { RegisterForm } from './RegisterForm';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { useAuthState } from '../../states/authState';

const { mutateAsyncLoginMock, mutateAsyncRegisterMock } = vi.hoisted(() => ({
  mutateAsyncLoginMock: vi.fn(),
  mutateAsyncRegisterMock: vi.fn(),
}));

vi.mock('../../hooks/useLogin', () => ({
  useLogin: () => ({
    mutateAsync: mutateAsyncLoginMock,
    isPending: false,
    error: null,
    reset: vi.fn(),
  }),
}));

vi.mock('../../hooks/useRegister', () => ({
  useRegister: () => ({
    mutateAsync: mutateAsyncRegisterMock,
    isPending: false,
    error: null,
    reset: vi.fn(),
  }),
}));

describe('AuthForms', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.setState({ token: null, user: null, role: null });
  });

  describe('LoginForm', () => {
    it('renders form and submits credentials successfully', async () => {
      const onSwitchToRegister = vi.fn();
      mutateAsyncLoginMock.mockResolvedValueOnce({
        token: 'header.' + btoa(JSON.stringify({ sub: 'u1', email: 'test@uct.cl', role: 'Student' })) + '.sig',
        userId: 'u1',
        email: 'test@uct.cl',
      });

      renderWithQueryClient(
        <MemoryRouter>
          <LoginForm onSwitchToRegister={onSwitchToRegister} />
        </MemoryRouter>,
      );

      expect(screen.getByRole('heading', { name: /iniciar sesión/i })).toBeInTheDocument();

      const emailInput = screen.getByPlaceholderText('usuario@uct.cl');
      const passwordInput = screen.getByPlaceholderText('••••••••');

      fireEvent.change(emailInput, { target: { value: 'test@uct.cl' } });
      fireEvent.change(passwordInput, { target: { value: 'password123' } });

      const submitButton = screen.getByRole('button', { name: 'Iniciar Sesión' });
      fireEvent.click(submitButton);

      expect(mutateAsyncLoginMock).toHaveBeenCalledWith({
        email: 'test@uct.cl',
        password: 'password123',
      });

      const registerLink = screen.getByRole('button', { name: 'Regístrate' });
      fireEvent.click(registerLink);
      expect(onSwitchToRegister).toHaveBeenCalled();
    });
  });

  describe('RegisterForm', () => {
    it('renders form and submits registration successfully', async () => {
      const onSwitchToLogin = vi.fn();
      vi.spyOn(window, 'alert').mockImplementation(() => {});
      mutateAsyncRegisterMock.mockResolvedValueOnce({ id: 'u1' });

      renderWithQueryClient(
        <MemoryRouter>
          <RegisterForm onSwitchToLogin={onSwitchToLogin} />
        </MemoryRouter>,
      );

      expect(screen.getByRole('heading', { name: /crear cuenta/i })).toBeInTheDocument();

      const nameInput = screen.getByPlaceholderText('Ej. Juan Pérez');
      const emailInput = screen.getByPlaceholderText('usuario@uct.cl');
      const passwordInputs = screen.getAllByPlaceholderText('••••••••');

      fireEvent.change(nameInput, { target: { value: 'Juan' } });
      fireEvent.change(emailInput, { target: { value: 'juan@uct.cl' } });
      fireEvent.change(passwordInputs[0], { target: { value: 'Password123!' } });
      fireEvent.change(passwordInputs[1], { target: { value: 'Password123!' } });

      const submitButton = screen.getByRole('button', { name: 'Registrarse' });
      fireEvent.click(submitButton);

      expect(mutateAsyncRegisterMock).toHaveBeenCalledWith({
        name: 'Juan',
        email: 'juan@uct.cl',
        password: 'Password123!',
      });

      const loginLink = screen.getByText('Inicia sesión');
      fireEvent.click(loginLink);
      expect(onSwitchToLogin).toHaveBeenCalled();
    });

    it('alerts when passwords do not match', () => {
      const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});
      renderWithQueryClient(
        <MemoryRouter>
          <RegisterForm onSwitchToLogin={vi.fn()} />
        </MemoryRouter>,
      );

      const passwordInputs = screen.getAllByPlaceholderText('••••••••');
      fireEvent.change(passwordInputs[0], { target: { value: 'pass1' } });
      fireEvent.change(passwordInputs[1], { target: { value: 'pass2' } });

      const submitButton = screen.getByRole('button', { name: 'Registrarse' });
      fireEvent.click(submitButton);

      expect(alertSpy).toHaveBeenCalledWith('Las contraseñas no coinciden');
      expect(mutateAsyncRegisterMock).not.toHaveBeenCalled();
    });
  });
});
