import httpClient from '../api/httpClient';
import { toApiError } from '../api/apiError';
import type { IdentityUserDto } from '../dtos/identity/IdentityUserDto';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';
import { Role, isRole } from '../constants/role';

export const userService = {
  getAllUsers: async (): Promise<UserIdentity[]> => {
    try {
      const { data } = await httpClient.get<IdentityUserDto[]>('/api/identity');

      return data.map((user) => ({
        id: user.userId,
        name: user.name,
        email: user.email,
        role: isRole(user.role) ? user.role : Role.Student,
        isSuspended: user.isSuspended,
      }));
    } catch (error) {
      throw toApiError(error, 'Error al cargar los usuarios');
    }
  },

  updateUserRole: async (userId: string, role: Role): Promise<void> => {
    try {
      await httpClient.put(`/api/identity/${userId}/roles`, { roles: [role] });
    } catch (error) {
      throw toApiError(error, 'Error al actualizar el rol del usuario');
    }
  },

  suspendUser: async (userId: string): Promise<void> => {
    try {
      await httpClient.post(`/api/identity/${userId}/suspension`, {});
    } catch (error) {
      throw toApiError(error, 'Error al suspender al usuario');
    }
  },

  reactivateUser: async (userId: string): Promise<void> => {
    try {
      await httpClient.delete(`/api/identity/${userId}/suspension`, {});
    } catch (error) {
      throw toApiError(error, 'Error al reactivar al usuario');
    }
  },
};
