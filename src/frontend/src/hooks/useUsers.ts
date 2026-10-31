import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { queryKeys } from '../api/queryKeys';
import { userService } from '../services/userService';
import type { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';

interface UpdateUserRoleVars {
  userId: string;
  role: Role;
}

interface ToggleUserSuspensionVars {
  userId: string;
  isSuspended: boolean;
}

export const useUsers = () => {
  return useQuery<UserIdentity[], Error>({
    queryKey: queryKeys.users,
    queryFn: () => userService.getAllUsers(),
  });
};

export const useUpdateUserRole = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, role }: UpdateUserRoleVars) => userService.updateUserRole(userId, role),
    onMutate: async ({ userId, role }) => {
      await queryClient.cancelQueries({ queryKey: queryKeys.users });
      const previous = queryClient.getQueryData<UserIdentity[]>(queryKeys.users);

      queryClient.setQueryData<UserIdentity[]>(queryKeys.users, (users) =>
        users?.map((user) => (user.id === userId ? { ...user, role } : user)),
      );

      return { previous };
    },
    onError: (_error, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData(queryKeys.users, context.previous);
      }
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: queryKeys.users }),
  });
};

export const useToggleUserSuspension = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, isSuspended }: ToggleUserSuspensionVars) =>
      isSuspended ? userService.suspendUser(userId) : userService.reactivateUser(userId),
    onMutate: async ({ userId, isSuspended }) => {
      await queryClient.cancelQueries({ queryKey: queryKeys.users });
      const previous = queryClient.getQueryData<UserIdentity[]>(queryKeys.users);

      queryClient.setQueryData<UserIdentity[]>(queryKeys.users, (users) =>
        users?.map((user) => (user.id === userId ? { ...user, isSuspended } : user)),
      );

      return { previous };
    },
    onError: (_error, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData(queryKeys.users, context.previous);
      }
    },
    onSettled: () => queryClient.invalidateQueries({ queryKey: queryKeys.users }),
  });
};
