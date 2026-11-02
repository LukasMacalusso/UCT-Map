import type React from 'react';
import type { RoleStyle } from '../interfaces/RoleStyle';
import RoleIcon from '../assets/svg/icons/icon_role.svg?react';
import StudyIcon from '../assets/svg/icons/icon_study.svg?react';
import BriefcaseIcon from '../assets/svg/icons/icon_briefcase.svg?react';
import ObjectsIcon from '../assets/svg/icons/icon_section_objects.svg?react';
import IncidentsIcon from '../assets/svg/icons/icon_section_incidents.svg?react';

export const Role = {
  Admin: 'Admin',
  Student: 'Student',
  Teacher: 'Teacher',
  ObjectsOfficer: 'ObjectsOfficer',
  ComplaintsOfficer: 'ComplaintsOfficer',
} as const;

export type Role = (typeof Role)[keyof typeof Role];
export const ROLES = Object.values(Role) as Role[];

export const OFFICIAL_ROLES: Role[] = [Role.Admin, Role.ObjectsOfficer, Role.ComplaintsOfficer];

export const isRole = (value: unknown): value is Role =>
  typeof value === 'string' && (ROLES as readonly string[]).includes(value);

export const ROLE_ICONS: Record<Role, React.ComponentType<React.SVGProps<SVGSVGElement>>> = {
  [Role.Admin]: RoleIcon,
  [Role.Student]: StudyIcon,
  [Role.Teacher]: BriefcaseIcon,
  [Role.ObjectsOfficer]: ObjectsIcon,
  [Role.ComplaintsOfficer]: IncidentsIcon,
};

export const ROLE_STYLES: Record<Role, RoleStyle> = {
  [Role.Admin]: { label: 'ADMINISTRADOR', color: 'purple', icon: ROLE_ICONS[Role.Admin] },
  [Role.Student]: { label: 'ESTUDIANTE', color: 'blue', icon: ROLE_ICONS[Role.Student] },
  [Role.Teacher]: { label: 'PROFESOR', color: 'dark', icon: ROLE_ICONS[Role.Teacher] },
  [Role.ObjectsOfficer]: { label: 'ENC. OBJETOS', color: 'blue', icon: ROLE_ICONS[Role.ObjectsOfficer] },
  [Role.ComplaintsOfficer]: { label: 'ENC. INCIDENTES', color: 'blue', icon: ROLE_ICONS[Role.ComplaintsOfficer] },
};
