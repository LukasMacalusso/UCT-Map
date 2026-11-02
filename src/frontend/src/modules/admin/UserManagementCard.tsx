import { useState } from 'react';
import { Role, ROLE_STYLES } from '../../constants/role';
import type { PageColor } from '../../constants/colors';
import { Avatar } from '../../components/media/Avatar';
import { Tag } from '../../components/ui/Tag';
import { Select } from '../../components/ui/Select';
import { Button } from '../../components/ui/Button';
import { IconText } from '../../components/ui/IconText';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { TimedActionCard } from '../../components/ui/TimedActionCard';
import MailIcon from '../../assets/svg/icons/icon_mail.svg?react';

export interface UserManagementCardProps {
  id: string;
  name: string;
  email: string;
  avatarSrc?: string;
  role: Role;
  isSuspended?: boolean;
  canToggleSuspension?: boolean;
  onViewProfile?: (userId: string) => void;
  onRoleChange?: (userId: string, newRole: Role) => void;
  onToggleSuspension?: (userId: string, isSuspended: boolean) => void;
}

type PendingAction =
  | { kind: 'role'; newRole: Role }
  | { kind: 'suspension'; suspend: boolean };

export const UserManagementCard = ({
  id,
  name,
  email,
  avatarSrc,
  role,
  isSuspended = false,
  canToggleSuspension = true,
  onViewProfile,
  onRoleChange,
  onToggleSuspension,
}: UserManagementCardProps) => {
  const [pending, setPending] = useState<PendingAction | null>(null);
  const [selectNonce, setSelectNonce] = useState(0);

  const roleOptions = [
    { value: Role.Student, label: 'Estudiante' },
    { value: Role.Teacher, label: 'Profesor' },
    { value: Role.ComplaintsOfficer, label: 'Encargado de Incidentes' },
    { value: Role.ObjectsOfficer, label: 'Encargado de Objetos' },
    { value: Role.Admin, label: 'Administrador' },
  ];

  const requestRoleChange = (value: string) => {
    const newRole = value as Role;
    if (newRole === role) return;
    setPending({ kind: 'role', newRole });
  };

  const requestToggleSuspension = () => {
    if (!canToggleSuspension) return;
    setPending({ kind: 'suspension', suspend: !isSuspended });
  };

  const handleCancel = () => {
    setPending(null);
    setSelectNonce((n) => n + 1);
  };

  const handleConfirm = () => {
    if (!pending) return;
    if (pending.kind === 'role') onRoleChange?.(id, pending.newRole);
    else onToggleSuspension?.(id, pending.suspend);
    setPending(null);
  };

  const confirm = !pending
    ? null
    : pending.kind === 'role'
      ? {
          title: 'Cambiar rol',
          description: `Vas a cambiar el rol de ${name} de ${ROLE_STYLES[role].label} a ${ROLE_STYLES[pending.newRole].label}. Esta acción se aplicará de inmediato.`,
          confirmLabel: 'Sí, cambiar rol',
          confirmColor: 'blue' as PageColor,
          duration: 2000,
        }
      : pending.suspend
        ? {
            title: 'Suspender cuenta',
            description: `${name} no podrá iniciar sesión hasta que un administrador reactive la cuenta.`,
            confirmLabel: 'Sí, suspender',
            confirmColor: 'red' as PageColor,
            duration: 3000,
          }
        : {
            title: 'Reactivar cuenta',
            description: `${name} podrá volver a iniciar sesión en la plataforma.`,
            confirmLabel: 'Sí, reactivar',
            confirmColor: 'green' as PageColor,
            duration: 2000,
          };

  const suspendedDim = isSuspended ? 'opacity-75 grayscale-[50%]' : '';

  return (
    <>
      <div className="flex flex-col md:flex-row items-center gap-6 bg-white p-4 rounded-3xl shadow-sm transition-all">

        {/* Avatar Custom Component */}
        <Avatar src={avatarSrc || null} alt={`Avatar de ${name}`} className={`w-16 h-16 ${suspendedDim}`} />

        {/* User Data */}
        <div className={`flex-1 min-w-0 text-center md:text-left ${suspendedDim}`}>
          <h3 className="text-xl font-bold text-gray-800 uppercase tracking-wide leading-tight flex flex-wrap items-center justify-center md:justify-start gap-2">
            {name}
            {isSuspended && (
              <Tag
                label="SUSPENDIDO"
                color="red"
                className="!text-xs !px-3 !py-1 font-semibold uppercase"
              />
            )}
          </h3>
          <div className="mt-1 flex justify-center md:justify-start">
            <IconText
              icon={<MailIcon className="w-5 h-5 flex-shrink-0" />}
              text={email}
              className="!text-sm font-medium"
            />
          </div>
        </div>

        {/* Actions (Role Select & Suspension Button) */}
        <div className="flex flex-col sm:flex-row items-center gap-4 w-full md:w-auto mt-2 md:mt-0">

          {/* Role Select Custom Component */}
          <div className={`w-full sm:w-64 ${isSuspended ? 'pointer-events-none opacity-60 grayscale-[50%]' : ''}`}>
            <Select
              key={`role-select-${selectNonce}`}
              label="Rol del Sistema"
              labelColor="text-gray-700"
              options={roleOptions}
              value={role}
              onChange={requestRoleChange}
            />
          </div>

          {/* Suspend / Reactivate Custom Button */}
          <div className="mt-2 sm:mt-5 flex items-center gap-3">
            <Button
              variant="outline"
              color="blue"
              className="!w-auto whitespace-nowrap !px-4 font-bold tracking-wide uppercase"
              onClick={() => onViewProfile?.(id)}
            >
              VER PERFIL
            </Button>
            <Button
              color={isSuspended ? 'green' : 'red'}
              variant="outline"
              className="!w-auto whitespace-nowrap !px-4 font-bold tracking-wide uppercase"
              onClick={requestToggleSuspension}
              disabled={!canToggleSuspension}
              title={canToggleSuspension ? undefined : 'No puedes suspender tu propia cuenta'}
            >
              {isSuspended ? 'REACTIVAR' : 'SUSPENDER'}
            </Button>
          </div>

        </div>

      </div>

      <ModalOverlay isOpen={!!pending} onClose={handleCancel}>
        {pending && confirm && (
          <TimedActionCard
            title={confirm.title}
            description={confirm.description}
            initialDurationMs={confirm.duration}
            options={[
              { label: 'Cancelar', color: 'gray', onClick: handleCancel },
              { label: confirm.confirmLabel, color: confirm.confirmColor, onClick: handleConfirm },
            ]}
          />
        )}
      </ModalOverlay>
    </>
  );
};
