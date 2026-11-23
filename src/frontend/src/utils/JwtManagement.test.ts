import { describe, it, expect } from 'vitest';
import { normalizeRole, decodeJwt, decodeBaseUrl, isTokenExpired } from './JwtManagement';
import { Role } from '../constants/role';

describe('JwtManagement utils', () => {
  describe('normalizeRole', () => {
    it('normalizes single valid role string', () => {
      expect(normalizeRole('Admin')).toBe(Role.Admin);
      expect(normalizeRole('Student')).toBe(Role.Student);
    });

    it('normalizes role array', () => {
      expect(normalizeRole(['Unknown', 'Teacher'])).toBe(Role.Teacher);
    });

    it('returns undefined for invalid role', () => {
      expect(normalizeRole('InvalidRole')).toBeUndefined();
      expect(normalizeRole(null)).toBeUndefined();
    });
  });

  describe('decodeBaseUrl', () => {
    it('decodes base64url string properly', () => {
      const original = '{"test":"value"}';
      const encoded = btoa(original).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
      expect(decodeBaseUrl(encoded)).toBe(original);
    });
  });

  describe('decodeJwt', () => {
    it('returns null for malformed tokens', () => {
      expect(decodeJwt('not.a.valid.jwt.token')).toBeNull();
      expect(decodeJwt('singlepart')).toBeNull();
    });

    it('decodes valid jwt and extracts claims', () => {
      const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
      const payloadObj = {
        sub: 'user-123',
        email: 'user@uct.cl',
        role: 'Admin',
        exp: Math.floor(Date.now() / 1000) + 3600,
      };
      const payload = btoa(JSON.stringify(payloadObj));
      const token = `${header}.${payload}.sig`;

      const decoded = decodeJwt(token);
      expect(decoded).not.toBeNull();
      expect(decoded?.sub).toBe('user-123');
      expect(decoded?.email).toBe('user@uct.cl');
      expect(decoded?.role).toBe(Role.Admin);
    });

    it('extracts ms claims mapping if standard ones not present', () => {
      const header = btoa(JSON.stringify({ alg: 'HS256' }));
      const payloadObj = {
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier': 'ms-sub-1',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress': 'ms@uct.cl',
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Teacher',
      };
      const payload = btoa(JSON.stringify(payloadObj));
      const token = `${header}.${payload}.sig`;

      const decoded = decodeJwt(token);
      expect(decoded?.sub).toBe('ms-sub-1');
      expect(decoded?.email).toBe('ms@uct.cl');
      expect(decoded?.role).toBe(Role.Teacher);
    });
  });

  describe('isTokenExpired', () => {
    it('returns false if token is null or lacks exp', () => {
      expect(isTokenExpired('invalid')).toBe(false);
    });

    it('returns true if exp is in the past', () => {
      const header = btoa(JSON.stringify({ alg: 'HS256' }));
      const payload = btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) - 100 }));
      const token = `${header}.${payload}.sig`;
      expect(isTokenExpired(token)).toBe(true);
    });

    it('returns false if exp is in the future', () => {
      const header = btoa(JSON.stringify({ alg: 'HS256' }));
      const payload = btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 1000 }));
      const token = `${header}.${payload}.sig`;
      expect(isTokenExpired(token)).toBe(false);
    });
  });
});
