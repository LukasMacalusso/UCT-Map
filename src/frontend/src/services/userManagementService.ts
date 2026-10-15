import httpClient from '../api/httpClient';
import type { IdentityUserDto } from '../dtos/identity/IdentityUserDto';
import { Role, isRole } from '../constants/role';

export interface UserManagementData {
  id: string;
  name: string;
  email: string;
  role: Role;
  rut: string;
  avatarSrc?: string;
  isBanned: boolean;
}

export const userManagementService = {
  async getAllUsers(): Promise<UserManagementData[]> {
    const response = await httpClient.get<IdentityUserDto[]>('/api/identity');
    return response.data.map(user => ({
      id: user.userId,
      name: user.name,
      email: user.email,
      role: isRole(user.role) ? user.role : Role.Student,
      rut: user.userId.length >= 12
        ? `${user.userId.slice(0, 2)}.${user.userId.slice(2, 5)}.${user.userId.slice(5, 8)}-${user.userId.slice(8, 9)}`
        : `ID: ${user.userId.slice(0, 8)}`,
      avatarSrc: undefined,
      isBanned: false,
    }));
  },

  async suspendUser(userId: string): Promise<void> {
    await httpClient.post(`/api/identity/${userId}/suspension`, {});
  },

  async reactivateUser(userId: string): Promise<void> {
    await httpClient.delete(`/api/identity/${userId}/suspension`, {});
  },
};
