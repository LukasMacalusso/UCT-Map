import httpClient from '../api/httpClient';
import type { IdentityUserDto } from '../dtos/identity/IdentityUserDto';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';
import { Role, isRole } from '../constants/role';

export const userManagementService = {
  async getAllUsers(): Promise<UserIdentity[]> {
    const response = await httpClient.get<IdentityUserDto[]>('/api/identity');

    return response.data.map((user) => ({
      id: user.userId,
      name: user.name,
      email: user.email,
      role: isRole(user.role) ? user.role : Role.Student,
      isSuspended: user.isSuspended,
    }));
  },

  async updateUserRole(userId: string, role: Role): Promise<void> {
    await httpClient.put(`/api/identity/${userId}/roles`, { roles: [role] });
  },

  async suspendUser(userId: string): Promise<void> {
    await httpClient.post(`/api/identity/${userId}/suspension`, {});
  },

  async reactivateUser(userId: string): Promise<void> {
    await httpClient.delete(`/api/identity/${userId}/suspension`, {});
  },
};
