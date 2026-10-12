export interface JwtPayload {
  id?: string;
  email?: string;
  role?: string;
  exp?: number;
  iss?: string;
  aud?: string;
  [key: string]: unknown;
}
