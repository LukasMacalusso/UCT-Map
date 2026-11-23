export interface IdentityUserDto {
  userId: string;
  name: string;
  email: string;
  role: string | null;
  isSuspended: boolean;
}
