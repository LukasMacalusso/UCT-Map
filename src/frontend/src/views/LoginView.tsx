import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import { Button } from '../components/ui/Button';
import { LoginForm } from '../modules/auth/LoginForm';
import { RegisterForm } from '../modules/auth/RegisterForm';
import logoUrl from '../assets/svg/logo.svg';
import LocationIcon from '../assets/svg/icons/icon_location.svg?react';

import bg1 from '../assets/images/uct_login_image_1.jpg';
import bg2 from '../assets/images/uct_login_image_2.jpg';
import bg3 from '../assets/images/uct_login_image_3.jpg';
import bg4 from '../assets/images/uct_login_image_4.jpg';
import bg5 from '../assets/images/uct_login_image_5.jpg';
import bg6 from '../assets/images/uct_login_image_6.jpg';
import bg7 from '../assets/images/uct_login_image_7.jpg';
import bg8 from '../assets/images/uct_login_image_8.jpg';
import bg9 from '../assets/images/uct_login_image_9.jpg';
import type { LoginBackgroundData } from '../interfaces/LoginBackgroundData';

const backgroundData: LoginBackgroundData[] = [
  { img: bg1, campus: 'Campus San Francisco', location: 'Edificio Central' },
  { img: bg2, campus: 'Campus Monseñor Alejandro Menchaca Lira', location: 'Casona Malmus' },
  { img: bg3, campus: 'Campus Monseñor Alejandro Menchaca Lira', location: 'Sala de Estudio' },
  { img: bg4, campus: 'Campus Monseñor Alejandro Menchaca Lira', location: 'Entrada' },
  { img: bg5, campus: 'Campus San Juan Pablo II', location: 'Laguna' },
  { img: bg6, campus: 'Campus San Juan Pablo II', location: 'Auditorio' },
  { img: bg7, campus: 'Campus Doctor Luis Rivas del Canto', location: 'Veterinaria' },
  { img: bg8, campus: 'Campus Nuestra Señora de Lourdes', location: 'Sala Principal' },
  { img: bg9, campus: 'Campus San Juan Pablo II', location: 'Edificio 8' },
];

export const LoginView = () => {
  const navigate = useNavigate();
  const mockLoginAs = useAuthState((state) => state.mockLoginAs);
  const logout = useAuthState((state) => state.logout);
  const [currentIndex, setCurrentIndex] = useState<number>(0);
  const [isRegistering, setIsRegistering] = useState(false);

  useEffect(() => {
    if (backgroundData.length === 0) return;

    // Random image
    const initialIndex = Math.floor(Math.random() * backgroundData.length);
    setCurrentIndex(initialIndex);

    // Change image
    const intervalId = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % backgroundData.length);
    }, 6000);

    return () => clearInterval(intervalId);
  }, []);

  const handleLogin = (role: Role) => {
    mockLoginAs(role);
    navigate('/map');
  };

  const handleGuest = () => {
    logout();
    navigate('/map');
  };

  return (
    <div className="w-full h-screen min-h-[500px] flex items-center justify-center lg:justify-start lg:pl-12 p-4 font-sans relative overflow-hidden bg-page-dark">

      {backgroundData.map((data, index) => {
        const isCurrent = index === currentIndex;
        const isPrevious = index === (currentIndex - 1 + backgroundData.length) % backgroundData.length;

        // Outer container classes
        let positionClass = 'opacity-0 translate-x-16';
        if (isCurrent) {
          positionClass = 'opacity-100 translate-x-0';
        } else if (isPrevious) {
          positionClass = 'opacity-0 -translate-x-16';
        }

        // Inner container classes
        let innerPosition = 'translate-x-0';
        let innerTransition = 'transition-none';

        if (isCurrent) {
          innerPosition = 'translate-x-8';
          innerTransition = 'transition-transform duration-[6000ms] ease-linear';
        } else if (isPrevious) {
          innerPosition = 'translate-x-8';
          innerTransition = 'transition-transform duration-[6000ms] ease-linear';
        }

        return (
          <div
            key={data.img}
            className={`absolute inset-0 transition-all duration-[1500ms] ease-in-out z-0 overflow-hidden ${positionClass}`}
          >
            {/* Panning image */}
            <div
              className={`absolute -inset-8 w-[calc(100%+4rem)] h-[calc(100%+4rem)] bg-cover bg-center scale-[1.25] ${innerTransition} ${innerPosition}`}
              style={{ backgroundImage: `url(${data.img})` }}
            />
          </div>
        );
      })}

      <div className="absolute inset-0 bg-black/40 z-0 pointer-events-none"></div>

      {backgroundData.map((data, index) => {
        const isCurrent = index === currentIndex;
        return (
          <div
            key={`${data.img}-info`}
            className={`absolute top-6 right-6 md:top-8 md:right-8 flex items-center gap-3 z-20 transition-opacity duration-[1500ms] ease-in-out ${isCurrent ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
          >
            <div className="flex flex-col items-end text-right">
              <span className="text-base sm:text-lg font-bold text-white tracking-wide drop-shadow-md">
                {data.campus}
              </span>
              <span className="text-xs sm:text-sm font-medium text-white/80 drop-shadow-md">
                {data.location}
              </span>
            </div>
            <LocationIcon className="w-7 h-7 sm:w-8 sm:h-8 text-white" />
          </div>
        );
      })}

      {/* Left panel */}
      <div className="w-full max-w-md lg:max-w-[30.75rem] max-h-[94vh] my-auto bg-gradient-to-b from-page-blue from-50% to-page-yellow to-50% p-1 rounded-[1.875rem] shadow-2xl relative z-10 flex flex-col">
        <div className="w-full flex-1 bg-white rounded-[1.625rem] p-6 sm:p-8 flex flex-col overflow-y-auto overflow-x-hidden">
          <div className="flex-grow flex flex-col justify-center">

            {/* Header */}
            <div className="flex items-center mb-5 sm:mb-6 flex-shrink-0">
              <img src={logoUrl} alt="UCT Logo" className="w-14 h-14 sm:w-16 sm:h-16 object-contain" />
              <div className="ml-4 flex flex-col justify-center">
                <span className="text-gray-800 font-black text-2xl sm:text-3xl leading-none tracking-wide block">UCT</span>
                <span className="text-gray-800 font-black text-2xl sm:text-3xl leading-none tracking-wide block">MAP</span>
              </div>
            </div>

            {/* Dynamic Form Area with Animations */}
            <div className="grid overflow-visible w-full">
              {/* Login View */}
              <div
                className={`col-start-1 row-start-1 w-full transition-all duration-500 ease-in-out ${isRegistering ? '-translate-x-8 opacity-0 pointer-events-none' : 'translate-x-0 opacity-100'}`}
              >
                <LoginForm onSwitchToRegister={() => setIsRegistering(true)} />
              </div>

              {/* Register View */}
              <div
                className={`col-start-1 row-start-1 w-full transition-all duration-500 ease-in-out ${isRegistering ? 'translate-x-0 opacity-100' : 'translate-x-8 opacity-0 pointer-events-none'}`}
              >
                <RegisterForm onSwitchToLogin={() => setIsRegistering(false)} />
              </div>
            </div>
          </div>

          <div className="mt-3 pt-3 flex-shrink-0">
            <div className="flex items-center mb-3">
              <div className="flex-grow border-t border-gray-200"></div>
              <span className="px-3 text-xs text-gray-400 font-medium">O bien</span>
              <div className="flex-grow border-t border-gray-200"></div>
            </div>

            <Button
              type="button"
              variant="outline"
              color="gray"
              size="md"
              className="w-full font-semibold"
              onClick={handleGuest}
            >
              Continuar como invitado
            </Button>
          </div>

        </div>
      </div>

      {/* Dev Tool Panel */}
      <div className="hidden md:flex absolute bottom-4 right-4 bg-white/95 backdrop-blur-sm p-3 rounded-2xl shadow-xl border border-gray-200 flex-col items-center gap-2.5 w-48 z-20">
        <div className="flex flex-col items-center gap-0">
          <h2 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Dev Tool</h2>
        </div>

        <div className="flex flex-col w-full gap-1.5">
          <Button onClick={handleGuest} color="gray" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Invitado
          </Button>

          <div className="w-full h-px bg-gray-100 my-0.5"></div>

          <Button onClick={() => handleLogin(Role.Student)} color="blue" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Estudiante
          </Button>

          <Button onClick={() => handleLogin(Role.Teacher)} color="dark" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Profesor
          </Button>

          <Button onClick={() => handleLogin(Role.ComplaintsOfficer)} color="blue" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Enc. Incidentes
          </Button>

          <Button onClick={() => handleLogin(Role.ObjectsOfficer)} color="blue" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Enc. Objetos
          </Button>

          <Button onClick={() => handleLogin(Role.Admin)} color="purple" size="sm" className="!w-full !px-2 !py-1 !text-xs">
            Admin
          </Button>
        </div>
      </div>

    </div>
  );
};
