import httpClient from '../api/httpClient';
import { toApiError } from '../api/apiError';

const LOGIN_ERRORS: Record<number, string> = {
  400: 'Datos incompletos o formato incorrecto',
  401: 'Credenciales inválidas',
  403: 'Cuenta suspendida o sin permisos para acceder',
  429: 'Demasiados intentos fallidos. Intenta más tarde',
  500: 'Error interno del servidor. Intenta más tarde',
};

const REGISTER_ERRORS: Record<number, string> = {
  400: 'Datos inválidos o el correo ya está registrado',
  500: 'Error interno del servidor. Intenta más tarde',
};

export const authService = {
  login: async (email: string, password: string) => {
    try {
      const { data } = await httpClient.post('/api/identity/login', { email, password });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al procesar la solicitud', LOGIN_ERRORS);
    }
  },

  register: async (name: string, email: string, password: string) => {
    try {
      const { data } = await httpClient.post('/api/identity/register', { name, email, password });
      return data;
    } catch (error) {
      throw toApiError(error, 'Error al procesar el registro', REGISTER_ERRORS);
    }
  },
};
