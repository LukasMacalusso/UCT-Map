import { useState, useMemo } from 'react';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import EyeIcon from '../../assets/svg/icons/icon_eye.svg?react';
import { useRegister } from '../../hooks/useRegister';

interface RegisterFormProps {
  onSwitchToLogin: () => void;
}

export const RegisterForm = ({ onSwitchToLogin }: RegisterFormProps) => {
  const [registerName, setRegisterName] = useState('');
  const [registerEmail, setRegisterEmail] = useState('');
  const [registerPassword, setRegisterPassword] = useState('');
  const [registerConfirmPassword, setRegisterConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const { mutateAsync: register, isPending: isRegisterLoading, error: registerError, reset: resetRegisterError } = useRegister();

  const passwordRules = useMemo(() => {
    return [
      { label: 'Mínimo 6 caracteres', valid: registerPassword.length >= 6 },
      { label: 'Una letra mayúscula', valid: /[A-Z]/.test(registerPassword) },
      { label: 'Una letra minúscula', valid: /[a-z]/.test(registerPassword) },
      { label: 'Un número', valid: /[0-9]/.test(registerPassword) },
      { label: 'Un carácter especial (ej. !@#$_-)', valid: /[^a-zA-Z0-9]/.test(registerPassword) },
    ];
  }, [registerPassword]);

  const strengthScore = useMemo(() => {
    if (!registerPassword) return 0;
    return passwordRules.filter((r) => r.valid).length;
  }, [passwordRules, registerPassword]);

  const isPasswordValid = strengthScore === 5;

  const strengthColor = useMemo(() => {
    if (strengthScore <= 2) return 'bg-red-500';
    if (strengthScore <= 4) return 'bg-yellow-500';
    return 'bg-green-500';
  }, [strengthScore]);

  const onRegisterSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    resetRegisterError();

    if (registerPassword !== registerConfirmPassword) {
      alert("Las contraseñas no coinciden");
      return;
    }

    if (!isPasswordValid) {
      alert("La contraseña no cumple con los requisitos de seguridad requeridos.");
      return;
    }

    try {
      await register({
        name: registerName,
        email: registerEmail,
        password: registerPassword
      });

      setRegisterName('');
      setRegisterEmail('');
      setRegisterPassword('');
      setRegisterConfirmPassword('');
      
      alert("¡Cuenta creada con éxito! Ahora inicia sesión.");
      onSwitchToLogin();
    } catch {
      return;
    }
  };

  return (
    <>
      <div className="flex flex-col gap-1 mb-3">
        <h1 className="text-2xl font-black text-gray-800 tracking-tight">Crear Cuenta</h1>
        <p className="text-gray-500 text-xs sm:text-sm font-medium">Únete para comenzar.</p>
      </div>

      <form onSubmit={onRegisterSubmit} className="flex flex-col gap-2.5">
        <Input
          label="Nombre Completo"
          labelColor="text-gray-700"
          placeholder="Ej. Juan Pérez"
          value={registerName}
          onChange={(e) => setRegisterName(e.target.value)}
        />
        <Input
          label="Email"
          labelColor="text-gray-700"
          placeholder="usuario@uct.cl"
          value={registerEmail}
          onChange={(e) => setRegisterEmail(e.target.value)}
        />
        <Input
          label="Contraseña"
          labelColor="text-gray-700"
          type={showPassword ? 'text' : 'password'}
          placeholder="••••••••"
          value={registerPassword}
          onChange={(e) => setRegisterPassword(e.target.value)}
          rightElement={
            <button
              type="button"
              tabIndex={-1}
              onClick={() => setShowPassword((v) => !v)}
              aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              className={`transition-colors ${showPassword ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}`}
            >
              <EyeIcon className="w-5 h-5" />
            </button>
          }
        />

        <Input
          label="Confirmar Contraseña"
          labelColor="text-gray-700"
          type={showConfirmPassword ? 'text' : 'password'}
          placeholder="••••••••"
          value={registerConfirmPassword}
          onChange={(e) => setRegisterConfirmPassword(e.target.value)}
          rightElement={
            <button
              type="button"
              tabIndex={-1}
              onClick={() => setShowConfirmPassword((v) => !v)}
              aria-label={showConfirmPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              className={`transition-colors ${showConfirmPassword ? 'text-page-blue' : 'text-gray-400 hover:text-gray-600'}`}
            >
              <EyeIcon className="w-5 h-5" />
            </button>
          }
        />

        {registerPassword.length > 0 && (
          <div className="flex flex-col gap-1.5 px-1 py-1">
            <div className="w-full bg-gray-200 h-1.5 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-300 ${strengthColor}`}
                style={{ width: `${(strengthScore / 5) * 100}%` }}
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-2 gap-y-0.5 text-[11px]">
              {passwordRules.map((rule) => (
                <div
                  key={rule.label}
                  className={`flex items-center gap-1.5 ${rule.valid ? 'text-green-600 font-semibold' : 'text-gray-400'}`}
                >
                  <span>{rule.valid ? '✓' : '○'}</span>
                  <span>{rule.label}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {registerError && (
          <div className="text-red-600 text-xs font-medium bg-red-50 p-2 rounded-lg border border-red-200">
            {registerError.message}
          </div>
        )}

        <Button type="submit" variant="solid" color="blue" size="md" className="w-full mt-1 font-bold tracking-wide" disabled={isRegisterLoading}>
          {isRegisterLoading ? 'Creando cuenta...' : 'Registrarse'}
        </Button>
      </form>

      <div className="mt-3.5 text-center text-xs sm:text-sm font-semibold text-gray-600">
        ¿Ya tienes cuenta?{' '}
        <button
          type="button"
          onClick={onSwitchToLogin}
          className="text-blue-600 hover:underline font-bold ml-1"
        >
          Inicia sesión
        </button>
      </div>
    </>
  );
};
