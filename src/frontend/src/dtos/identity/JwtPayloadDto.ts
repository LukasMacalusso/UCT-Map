export interface JwtPayloadDto {
  id?: string;
  sub?: string;
  name?: string;
  email?: string;
  role?: string;
  exp?: number;
  iss?: string;
  aud?: string;
  [key: string]: unknown;
}
