import type { Role } from '../../constants/role';

export interface UserIdentity {
  id: string;
  role: Role;
  name: string;
  email: string;
  registeredAt: string;
  avatar?: string;
  isSuspended?: boolean;
}
