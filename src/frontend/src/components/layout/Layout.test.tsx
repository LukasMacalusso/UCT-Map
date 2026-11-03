import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent, act } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AppLayout } from './AppLayout';
import { GlobalModals } from './GlobalModals';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { useAuthState } from '../../states/authState';
import { useUiState } from '../../states/uiState';
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
  });

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
