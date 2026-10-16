import type { LoginRequestDto } from '../dtos/identity/LoginRequestDto';
import { useMutation } from '@tanstack/react-query';
import { authService } from '../services/authService';

export const useLogin = () => {
  return useMutation({
    mutationFn: (data: LoginRequestDto) => authService.login(data.email, data.password),
  });
};
