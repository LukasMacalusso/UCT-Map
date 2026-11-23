import type { RegisterRequestDto } from '../dtos/identity/RegisterRequestDto';
import { useMutation } from '@tanstack/react-query';
import { authService } from '../services/authService';

export const useRegister = () => {
  return useMutation({
    mutationFn: (data: RegisterRequestDto) => authService.register(data.name, data.email, data.password),
  });
};
