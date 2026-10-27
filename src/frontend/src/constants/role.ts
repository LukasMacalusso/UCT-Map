import type { RoleStyle } from '../interfaces/RoleStyle';

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

export const ROLE_STYLES: Record<Role, RoleStyle> = {
  [Role.Admin]: { label: 'ADMINISTRADOR', color: 'purple' },
  [Role.Student]: { label: 'ESTUDIANTE', color: 'blue' },
  [Role.Teacher]: { label: 'PROFESOR', color: 'dark' },
  [Role.ObjectsOfficer]: { label: 'ENC. OBJETOS', color: 'blue' },
  [Role.ComplaintsOfficer]: { label: 'ENC. INCIDENTES', color: 'blue' },
};
