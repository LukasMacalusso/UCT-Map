import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AppLayout } from './AppLayout';
import { GlobalModals } from './GlobalModals';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { useAuthState } from '../../states/authState';
import { useUiState } from '../../states/uiState';
import { useNavStore } from '../../states/navState';
import { Role } from '../../constants/role';

vi.mock('../../hooks/useCampus', () => ({
  useCampuses: () => ({ data: [], isLoading: false }),
  useStructures: () => ({ data: [], isLoading: false }),
}));

vi.mock('../../hooks/useReports', () => ({
  useReports: () => ({ data: { items: [], totalPages: 1 }, isLoading: false }),
  useUpdateReportStatus: () => ({ mutate: vi.fn(), isPending: false }),
}));

vi.mock('../../hooks/useLostObjects', () => ({
  useLostObjectsByIds: () => ({ data: [], isLoading: false }),
}));

vi.mock('../../hooks/useSchedule', () => ({
  useAllMeetings: () => ({ data: [], isLoading: false }),
  useUpdateMeetingStatus: () => ({ mutate: vi.fn(), isPending: false }),
}));

vi.mock('../../hooks/useUsers', () => ({
  useUsers: () => ({ data: [], isLoading: false }),
}));

describe('Layout components', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useAuthState.getState().mockLoginAs(Role.Admin);
    useUiState.setState({ activePanel: 'none', editorToast: null });
    useNavStore.setState({ isHidden: false, isExpanded: false });
  });

  const renderAt = (path: string) =>
    renderWithQueryClient(
      <MemoryRouter initialEntries={[path]}>
        <Routes>
          <Route path="/" element={<AppLayout />}>
            <Route path="*" element={<div>Contenido</div>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    );

  describe('AppLayout', () => {
    it('renders navigation buttons, user avatar, and responds to keyboard shortcut', () => {
      renderWithQueryClient(
        <MemoryRouter initialEntries={['/map']}>
          <Routes>
            <Route path="/" element={<AppLayout />}>
              <Route path="map" element={<div>Contenido del Mapa</div>} />
            </Route>
          </Routes>
        </MemoryRouter>,
      );

      expect(screen.getByText('Contenido del Mapa')).toBeInTheDocument();
      expect(screen.getAllByText('ADMINISTRADOR').length).toBeGreaterThan(0);

      // Test 'h' key shortcut to hide navbar
      fireEvent.keyDown(window, { key: 'h' });
    });

    it.each([
      '/edition',
      '/map',
      '/reports',
      '/objects',
      '/contacts',
      '/schedule',
      '/showcase',
      '/administration',
      '/otra-ruta',
    ])('resolves the page title for %s', (path) => {
      renderAt(path);
      expect(screen.getByText('Contenido')).toBeInTheDocument();
    });

    it('toggles the navbar with the h shortcut and ignores modifiers and form fields', () => {
      renderAt('/map');

      expect(useNavStore.getState().isHidden).toBe(false);
      fireEvent.keyDown(window, { key: 'h' });
      expect(useNavStore.getState().isHidden).toBe(true);

      fireEvent.keyDown(window, { key: 'H' });
      expect(useNavStore.getState().isHidden).toBe(false);

      fireEvent.keyDown(window, { key: 'h', ctrlKey: true });
      fireEvent.keyDown(window, { key: 'h', metaKey: true });
      fireEvent.keyDown(window, { key: 'h', altKey: true });
      fireEvent.keyDown(window, { key: 'x' });
      expect(useNavStore.getState().isHidden).toBe(false);

      const input = document.createElement('input');
      const textarea = document.createElement('textarea');
      const select = document.createElement('select');
      const editable = document.createElement('div');
      Object.defineProperty(editable, 'isContentEditable', { value: true });
      document.body.append(input, textarea, select, editable);

      fireEvent.keyDown(input, { key: 'h' });
      fireEvent.keyDown(textarea, { key: 'h' });
      fireEvent.keyDown(select, { key: 'h' });
      fireEvent.keyDown(editable, { key: 'h' });
      expect(useNavStore.getState().isHidden).toBe(false);

      input.remove();
      textarea.remove();
      select.remove();
      editable.remove();
    });

    it('expands and collapses the navbar on hover', () => {
      renderAt('/map');

      const nav = screen.getByRole('navigation');
      fireEvent.mouseEnter(nav);
      expect(useNavStore.getState().isExpanded).toBe(true);

      fireEvent.mouseLeave(nav);
      expect(useNavStore.getState().isExpanded).toBe(false);
    });

    it('keeps the navbar collapsed while hidden', () => {
      useNavStore.setState({ isHidden: true, isExpanded: false });
      renderAt('/map');

      const nav = screen.getByRole('navigation');
      expect(nav.className).toContain('-translate-x-full');

      fireEvent.mouseEnter(nav);
      expect(useNavStore.getState().isExpanded).toBe(false);

      fireEvent.keyDown(window, { key: 'h' });
      expect(useNavStore.getState().isHidden).toBe(false);
    });

    it('shows the login action for guests and the account button for users', () => {
      useAuthState.setState({ user: null, token: null, isAuthenticated: false });
      const guest = renderAt('/map');
      expect(screen.getByText('Iniciar Sesión')).toBeInTheDocument();
      guest.unmount();

      useAuthState.getState().mockLoginAs(Role.Student);
      renderAt('/map');
      expect(screen.getByTitle('Información de cuenta')).toBeInTheDocument();

      fireEvent.click(screen.getByTitle('Información de cuenta'));
      expect(useUiState.getState().activePanel).toBe('userProfile');
    });

    it('shows role-specific sections', () => {
      useAuthState.getState().mockLoginAs(Role.Teacher);
      const teacher = renderAt('/map');
      expect(screen.getByText('Agendamiento')).toBeInTheDocument();
      expect(screen.queryByText('Administración')).not.toBeInTheDocument();
      teacher.unmount();

      useAuthState.getState().mockLoginAs(Role.Student);
      renderAt('/map');
      expect(screen.queryByText('Agendamiento')).not.toBeInTheDocument();
      expect(screen.queryByText('Administración')).not.toBeInTheDocument();
    });
  });

  describe('GlobalModals', () => {
    it('renders user profile when activePanel is userProfile', () => {
      useUiState.setState({ activePanel: 'userProfile' });

      renderWithQueryClient(
        <MemoryRouter initialEntries={['/map']}>
          <GlobalModals />
        </MemoryRouter>,
      );

      expect(screen.getByText('ADMINISTRADOR')).toBeInTheDocument();
    });

    it('renders and interacts with saveMapChanges modal', () => {
      vi.useFakeTimers();
      useUiState.setState({ activePanel: 'saveMapChanges' });

      renderWithQueryClient(
        <MemoryRouter initialEntries={['/map']}>
          <GlobalModals />
        </MemoryRouter>,
      );

      expect(screen.getByText('Confirmar Cambios')).toBeInTheDocument();
      act(() => {
        vi.advanceTimersByTime(3100);
      });
      const publishBtn = screen.getByText('Publicar Mapa');
      fireEvent.click(publishBtn);
      expect(useUiState.getState().activePanel).toBe('none');
      vi.useRealTimers();
    });

    it('renders and interacts with discardMapChanges modal', () => {
      vi.useFakeTimers();
      useUiState.setState({ activePanel: 'discardMapChanges' });

      renderWithQueryClient(
        <MemoryRouter initialEntries={['/map']}>
          <GlobalModals />
        </MemoryRouter>,
      );

      expect(screen.getByText('Descartar Cambios')).toBeInTheDocument();
      act(() => {
        vi.advanceTimersByTime(2100);
      });
      const discardBtn = screen.getByText('Sí, descartar');
      fireEvent.click(discardBtn);
      expect(useUiState.getState().activePanel).toBe('none');
      vi.useRealTimers();
    });

    it('renders toast when editorToast is set', () => {
      useUiState.setState({
        activePanel: 'none',
        editorToast: { id: 1, message: 'Cambios guardados', type: 'success' },
      });

      renderWithQueryClient(
        <MemoryRouter initialEntries={['/map']}>
          <GlobalModals />
        </MemoryRouter>,
      );

      expect(screen.getByText('Cambios guardados')).toBeInTheDocument();
    });
  });
});
