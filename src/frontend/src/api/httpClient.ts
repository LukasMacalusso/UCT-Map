import axios from 'axios';
import { useAuthState } from '../states/authState';
import { decodeJwt } from '../utils/JwtManagement';

const httpClient = axios.create({
  headers: { 'Content-Type': 'application/json' },
  timeout: 10000
});

const ERROR_HANDLERS: Record<number, () => void> = {
  401: () => {
    const { token } = useAuthState.getState();
    if (token && decodeJwt(token)?.isMock === true) return;
    useAuthState.getState().logout();
  },
  403: () => console.warn('You do not have permission'),
  404: () => console.warn('Resource not found'),
};

httpClient.interceptors.request.use(
  (config) => {
    const token = useAuthState.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

httpClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (!error.response) {
      console.error('Network error. No response received from the server');
      return Promise.reject(error);
    }

    const { status } = error.response;
    const handler = ERROR_HANDLERS[status];

    if (handler) {
      handler();
    } else if (status >= 500) {
      console.error('Server error');
    }

    return Promise.reject(error);
  }
);

export default httpClient;
