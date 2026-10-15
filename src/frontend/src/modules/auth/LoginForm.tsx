import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthState } from '../../states/authState';

import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { useLogin } from '../../hooks/useLogin';
import { decodeJwt } from '../../utils/JwtManagement';
import { Role, isRole } from '../../constants/role';

interface LoginFormProps {
  onSwitchToRegister: () => void;
}

export const LoginForm = ({ onSwitchToRegister }: LoginFormProps) => {
  const navigate = useNavigate();
  const realLogin = useAuthState((state) => state.login);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const { mutateAsync: login, isPending: isLoading, error, reset: resetError } = useLogin();

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    resetError();

    try {
      const response = await login({ email, password });
      const token = response.token || '';
      const decoded = decodeJwt(token);

      const assignedRole = isRole(decoded?.role) ? decoded.role : Role.Student;
      const userName = email.split('@')[0];

      realLogin(token, {
        id: response.userId || decoded?.sub || 'user_id',
        email: response.email || decoded?.email || email,
        name: userName,
        role: assignedRole,
        registeredAt: new Date().toISOString()
      });
      
      navigate('/map');
    } catch {
      // Handled by hook error state
    }
  };

  return (
    <>
      <div className="flex flex-col gap-1 mb-4">
        <h1 className="text-2xl font-black text-gray-800 tracking-tight">Iniciar Sesión</h1>
        <p className="text-gray-500 text-xs sm:text-sm font-medium">Ingresa tus credenciales institucionales.</p>
      </div>

      <form onSubmit={onSubmit} className="flex flex-col gap-3.5">
        <Input
          label="Email"
          labelColor="text-gray-700"
          placeholder="usuario@uct.cl"
          value={email}
          onChange={(e: any) => setEmail(e.target.value)}
        />
        <Input
          label="Contraseña"
          labelColor="text-gray-700"
          type="password"
          placeholder="••••••••"
          value={password}
          onChange={(e: any) => setPassword(e.target.value)}
        />

        {error && (
          <div className="text-red-600 text-xs font-medium bg-red-50 p-2 rounded-lg border border-red-200">
            {error.message}
          </div>
        )}

        <Button type="submit" variant="solid" color="blue" size="md" className="w-full mt-1 font-bold tracking-wide" disabled={isLoading}>
          {isLoading ? 'Cargando...' : 'Iniciar Sesión'}
        </Button>
      </form>

      <div className="mt-4 text-center text-xs sm:text-sm font-semibold text-gray-600">
        ¿No tienes cuenta?{' '}
        <button
          type="button"
          onClick={onSwitchToRegister}
          className="text-blue-600 hover:underline font-bold ml-1"
        >
          Regístrate
        </button>
      </div>
    </>
  );
};
