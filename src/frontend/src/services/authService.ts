import httpClient from '../api/httpClient';

export const authService = {
  login: async (email: string, password: string) => {
    try {
      const response = await httpClient.post('/api/identity/login', { email, password });
      return response.data;
    } catch (err: any) {
      const status = err.response?.status;

      if (status === 400) {
        throw new Error('Datos incompletos o formato incorrecto');
      } else if (status === 401) {
        throw new Error('Credenciales inválidas');
      } else if (status === 403) {
        throw new Error('Cuenta suspendida o sin permisos para acceder');
      } else if (status === 429) {
        throw new Error('Demasiados intentos fallidos. Intenta más tarde');
      } else if (status >= 500) {
        throw new Error('Error interno del servidor. Intenta más tarde');
      } else if (typeof err.response?.data === 'string' && err.response.data.trim()) {
        throw new Error(err.response.data);
      } else {
        throw new Error('Error al procesar la solicitud');
      }
    }
  },

  register: async (name: string, email: string, password: string) => {
    try {
      const response = await httpClient.post('/api/identity/register', { name, email, password });
      return response.data;
    } catch (err: any) {
      const status = err.response?.status;

      if (status === 400) {
        throw new Error('Datos inválidos o el correo ya está registrado');
      } else if (status >= 500) {
        throw new Error('Error interno del servidor. Intenta más tarde');
      } else if (typeof err.response?.data === 'string' && err.response.data.trim()) {
        throw new Error(err.response.data);
      } else {
        throw new Error('Error al procesar el registro');
      }
    }
  }
};
