import { useState } from 'react';
import type { Role } from '../../constants/role';
import { Avatar } from '../../components/media/Avatar';
import { Tag } from '../../components/ui/Tag';
import { Select } from '../../components/ui/Select';
import { Button } from '../../components/ui/Button';

export interface UserManagementCardProps {
  id: string;
  name: string;
  rut: string;
  email: string;
  avatarSrc?: string;
  initialRole: Role;
  isBanned?: boolean;
  onRoleChange?: (userId: string, newRole: Role) => void;
  onToggleBan?: (userId: string, isBanned: boolean) => void;
}

export const UserManagementCard = ({
  id,
  name,
  rut,
  email,
  avatarSrc,
  initialRole,
  isBanned = false,
  onRoleChange,
  onToggleBan,
}: UserManagementCardProps) => {
  const [currentRole, setCurrentRole] = useState<Role>(initialRole);

  const handleRoleChange = (newRoleValue: string) => {
    const newRole = newRoleValue as Role;
    setCurrentRole(newRole);
    if (onRoleChange) onRoleChange(id, newRole);
  };

  const roleOptions = [
    { value: 'MEMBER', label: 'Miembro' },
    { value: 'TEACHER', label: 'Profesor' },
    { value: 'OFFICIAL', label: 'Funcionario' },
    { value: 'INCIDENTS_OFFICER', label: 'Encargado de Incidentes' },
    { value: 'OBJECTS_OFFICER', label: 'Encargado de Objetos' },
    { value: 'ADMIN', label: 'Administrador' },
  ];

  return (
    <div className={`flex flex-col md:flex-row items-center gap-6 bg-white p-4 rounded-3xl shadow-sm transition-all ${isBanned ? 'opacity-75 grayscale-[50%]' : ''}`}>

      {/* Avatar Custom Component */}
      <Avatar src={avatarSrc || null} alt={`Avatar de ${name}`} className="w-16 h-16" />

      {/* User Data */}
      <div className="flex-1 text-center md:text-left">
        <h3 className="font-bold text-gray-800 text-lg flex flex-wrap items-center justify-center md:justify-start gap-2">
          {name}
          {isBanned && <Tag label="Baneado" color="red" className="!text-[10px] px-2 py-0.5" />}
        </h3>
        <p className="text-sm text-gray-500 font-medium">{rut}</p>
        <p className="text-xs text-gray-400">{email}</p>
      </div>

      {/* Actions (Role Select & Ban Button) */}
      <div className="flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto mt-2 md:mt-0">

        {/* Role Select Custom Component */}
        <div className={`w-full sm:w-64 ${isBanned ? 'pointer-events-none opacity-60' : ''}`}>
          <Select
            label="Rol del Sistema"
            labelColor="text-gray-400"
            options={roleOptions}
            value={currentRole}
            onChange={handleRoleChange}
          />
        </div>

        {/* Ban / Unban Custom Button */}
        <div className="mt-2 sm:mt-5">
          <Button
            color={isBanned ? 'gray' : 'red'}
            variant={isBanned ? 'solid' : 'outline'}
            className="!w-auto whitespace-nowrap !px-4"
            onClick={() => onToggleBan && onToggleBan(id, !isBanned)}
          >
            {isBanned ? 'Restaurar Cuenta' : 'Suspender'}
          </Button>
        </div>

      </div>

    </div>
  );
};
