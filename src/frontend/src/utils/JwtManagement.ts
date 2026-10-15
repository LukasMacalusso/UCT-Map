import type { JwtPayloadDto } from "../dtos/identity/JwtPayloadDto";

export function decodeJwt(token: string): JwtPayloadDto | null {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const baseUrl = parts[1];
    const jsonString = decodeBaseUrl(baseUrl);
    const parsed = JSON.parse(jsonString);

    // claims mapping
    const msRole = parsed['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    const msEmail = parsed['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
    const msSub = parsed['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];

    const payload: JwtPayloadDto = {
      ...parsed,
      role: parsed.role || msRole,
      email: parsed.email || msEmail,
      sub: parsed.sub || msSub,
    };

    return payload;
  }
  catch {
    return null;
  }
}

export function decodeBaseUrl(baseurl: string): string {
  let base64 = baseurl.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4 !== 0) {
    base64 += '=';
  }
  return decodeURIComponent(
    atob(base64)
      .split('')
      .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
      .join('')
  );
}

export function isTokenExpired(token: string): boolean {
  const payload = decodeJwt(token);
  if (!payload || !payload.exp) return false;
  return Date.now() >= payload.exp * 1000;
}
