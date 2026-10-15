// Respuesta del endpoint GET /api/identity (contrato de red)
export interface IdentityUserDto {
  userId: string;
  name: string;
  email: string;
  role: string | null;
  isSuspended: boolean;
}
