import { create } from "zustand";
import type { Role } from "../constants/role";
import type { UserIdentity } from "../interfaces/identities/UserIdentity";
import { isTokenExpired } from "../utils/JwtManagement";

interface AuthState {
  user: UserIdentity | null;
  token: string | null;
  isAuthenticated: boolean;

  login: (token: string, user: UserIdentity) => void;
  logout: () => void;

  mockLoginAs: (role: Role) => void;
}

const removeItems = () => {
  localStorage.removeItem('jwt_token');
  localStorage.removeItem('user_identity');
};

const addItems = (token: string, user: string) => {
  localStorage.setItem('jwt_token', token);
  localStorage.setItem('user_identity', user);
};

const buildMockToken = (role: Role): string => {
  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const header = { alg: 'none', typ: 'JWT' };
  const payload = {
    sub: '123',
    email: `${role.toLowerCase()}@uct.cl`,
    role,
    isMock: true,
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 365,
  };

  return `${encode(header)}.${encode(payload)}.mock`;
};

const getInitialAuth = () => {
  const token = localStorage.getItem("jwt_token");
  const userJson = localStorage.getItem("user_identity");

  if (!token || isTokenExpired(token)) {
    removeItems();
    return { token: null, user: null, isAuthenticated: false };
  }

  try {
    const user: UserIdentity | null = userJson ? JSON.parse(userJson) : null;
    return {
      token,
      user,
      isAuthenticated: !!user,
    };
  } catch {
    return { token, user: null, isAuthenticated: false };
  }
};

const initial = getInitialAuth();

export const useAuthState = create<AuthState>((set) => ({
  user: initial.user,
  token: initial.token,
  isAuthenticated: initial.isAuthenticated,

  login: (token, user) => {
    addItems(token, JSON.stringify(user));
    set({ user, token, isAuthenticated: true });
  },

  logout: () => {
    removeItems();
    set({ user: null, token: null, isAuthenticated: false });
  },

  mockLoginAs: (role) => {
    const mockUser: UserIdentity = {
      id: '123',
      role: role,
      name: `${role}`,
      email: `${role.toLowerCase()}@uct.cl`,
      registeredAt: new Date().toISOString()
    };
    const mockToken = buildMockToken(role);
    addItems(mockToken, JSON.stringify(mockUser));
    set({ user: mockUser, token: mockToken, isAuthenticated: true });
  }
}));
