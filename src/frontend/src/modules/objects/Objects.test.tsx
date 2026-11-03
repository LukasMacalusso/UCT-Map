import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { ObjectReportCard } from './ObjectReportCard';
import { ReportLostObjectCard } from './ReportLostObjectCard';
import { PublishReportCard } from './PublishReportCard';
import { ChangeObjectStatusModal } from './ChangeObjectStatusModal';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { LostObjectStatus } from '../../constants/lostObjectsStatus';
import type { LostObjectDto } from '../../dtos/incident/objects/LostObjectDto';

vi.mock('../../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Biblioteca', campusId: 'c1' }],
    isLoading: false,
  }),
  useBuildingLocations: () => ({
    data: [{ id: 'b1', name: 'Edificio A', metadata: { campusId: 'c1' } }],
    isLoading: false,
  }),
}));

const mockUpdateLostObjectStatus = vi.fn();
vi.mock('../../hooks/useLostObjects', () => ({
  useUpdateLostObjectStatus: () => ({
    mutate: mockUpdateLostObjectStatus,
    isPending: false,
  }),
}));

describe('Objects modules', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('ObjectReportCard', () => {
    it('renders object details and triggers status click', () => {
      const onStatusChangeClick = vi.fn();
      renderWithQueryClient(
        <ObjectReportCard
          title="Notebook Dell"
          building="Biblioteca"
          campus="San Juan"
          status="Pendiente"
          actions={[
            {
              actorRole: 'Student',
              actorName: 'Camila',
              actionText: 'Reportado',
              actionDate: 'Hace 1h',
            },
          ]}
          onStatusChangeClick={onStatusChangeClick}
        />,
      );

      expect(screen.getByText('Notebook Dell')).toBeInTheDocument();
      expect(screen.getByText('Biblioteca')).toBeInTheDocument();

      const changeBtn = screen.getByRole('button', { name: /cambiar estado/i });
      fireEvent.click(changeBtn);
      expect(onStatusChangeClick).toHaveBeenCalled();
    });
  });

  describe('ReportLostObjectCard', () => {
    it('submits lost object report', () => {
      const onPublish = vi.fn();
      renderWithQueryClient(
        <ReportLostObjectCard onPublish={onPublish} onDiscard={vi.fn()} />,
      );

      expect(screen.getByText('REPORTAR OBJETO PERDIDO')).toBeInTheDocument();

      const titleInput = screen.getByPlaceholderText('¿QUÉ SE PERDIÓ?');
      fireEvent.change(titleInput, { target: { value: 'Billetera' } });

      const publishBtn = screen.getByRole('button', { name: /reportar perdido/i });
      fireEvent.click(publishBtn);

      expect(onPublish).toHaveBeenCalledWith({
        title: 'Billetera',
        description: '',
        structureId: 'b1',
        files: [],
      });
    });
  });

  describe('PublishReportCard', () => {
    it('submits object report', () => {
      const onPublish = vi.fn();
      renderWithQueryClient(
        <PublishReportCard onPublish={onPublish} onDiscard={vi.fn()} />,
      );

      const titleInput = screen.getByPlaceholderText('TITULO');
      const descInput = screen.getByPlaceholderText('DESCRIPCIÓN');

      fireEvent.change(titleInput, { target: { value: 'Celular' } });
      fireEvent.change(descInput, { target: { value: 'Funda negra' } });

      const publishBtn = screen.getByRole('button', { name: /publicar/i });
      fireEvent.click(publishBtn);

      expect(onPublish).toHaveBeenCalledWith({
        title: 'Celular',
        description: 'Funda negra',
        structureId: 's1',
        files: [],
      });
    });
  });

  describe('ChangeObjectStatusModal', () => {
    it('saves updated status', () => {
      const onClose = vi.fn();
      const mockObject: LostObjectDto = {
        id: 'lo1',
        lostObjectId: 'lo1',
        title: 'Billetera',
        status: LostObjectStatus.Pending,
        structureId: 's1',
        createdAt: '2026-11-03',
      };

      renderWithQueryClient(
        <ChangeObjectStatusModal isOpen={true} onClose={onClose} lostObject={mockObject} />,
      );

      expect(screen.getByText(/cambiar estado del objeto/i)).toBeInTheDocument();

      const resolvedOption = screen.getByText('RESUELTO');
      fireEvent.click(resolvedOption);

      const saveBtn = screen.getByRole('button', { name: /guardar estado/i });
      fireEvent.click(saveBtn);

      expect(mockUpdateLostObjectStatus).toHaveBeenCalledWith(
        { id: 'lo1', status: LostObjectStatus.Resolved },
        expect.any(Object),
      );
    });
  });
});
