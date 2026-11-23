import { render, screen } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { ProtectedRoute } from './ProtectedRoute';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';

describe('ProtectedRoute Guard', () => {
  beforeEach(() => {
    useAuthState.getState().logout();
  });

  it('redirects to unauthorized destination when user is not authenticated', () => {
    render(
      <MemoryRouter initialEntries={['/private']}>
        <Routes>
          <Route path="/login" element={<div>Login Screen</div>} />
          <Route element={<ProtectedRoute unauthorizedTo="/login" />}>
            <Route path="/private" element={<div>Secret Content</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Login Screen')).toBeInTheDocument();
    expect(screen.queryByText('Secret Content')).not.toBeInTheDocument();
  });

  it('allows access when user is authenticated', () => {
    useAuthState.getState().mockLoginAs(Role.Student);

    render(
      <MemoryRouter initialEntries={['/private']}>
        <Routes>
          <Route element={<ProtectedRoute />}>
            <Route path="/private" element={<div>Secret Content</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Secret Content')).toBeInTheDocument();
  });

  it('blocks access when user role is not in allowedRoles', () => {
    useAuthState.getState().mockLoginAs(Role.Student);

    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route path="/map" element={<div>Map View</div>} />
          <Route element={<ProtectedRoute allowedRoles={[Role.Admin]} unauthorizedTo="/map" />}>
            <Route path="/admin" element={<div>Admin Panel</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Map View')).toBeInTheDocument();
    expect(screen.queryByText('Admin Panel')).not.toBeInTheDocument();
  });

  it('allows access when user role matches allowedRoles', () => {
    useAuthState.getState().mockLoginAs(Role.Admin);

    render(
      <MemoryRouter initialEntries={['/admin']}>
        <Routes>
          <Route element={<ProtectedRoute allowedRoles={[Role.Admin]} />}>
            <Route path="/admin" element={<div>Admin Panel</div>} />
          </Route>
        </Routes>
      </MemoryRouter>
    );

    expect(screen.getByText('Admin Panel')).toBeInTheDocument();
  });
});
