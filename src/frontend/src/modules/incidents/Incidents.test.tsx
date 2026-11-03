import { describe, it, expect, vi, beforeEach } from 'vitest';
import { screen, fireEvent } from '@testing-library/react';
import { IncidentCard } from './IncidentCard';
import { PublishReportCard } from './PublishReportCard';
import { ChangeReportStatusModal } from './ChangeReportStatusModal';
import { renderWithQueryClient } from '../../test/renderWithQueryClient';
import { TicketStatus } from '../../constants/ticketStatus';
import type { ReportDto } from '../../dtos/incident/reports/ReportDto';

vi.mock('../../hooks/useCampus', () => ({
  useCampuses: () => ({
    data: [{ id: 'c1', name: 'Campus San Juan' }],
    isLoading: false,
  }),
  useStructures: () => ({
    data: [{ id: 's1', name: 'Edificio A', campusId: 'c1' }],
    isLoading: false,
  }),
}));

const mockUpdateStatusMutate = vi.fn();
vi.mock('../../hooks/useReports', () => ({
  useUpdateReportStatus: () => ({
    mutate: mockUpdateStatusMutate,
    isPending: false,
  }),
}));

describe('Incidents modules', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('IncidentCard', () => {
    it('renders incident card information and triggers status change', () => {
      const onStatusChangeClick = vi.fn();
      renderWithQueryClient(
        <IncidentCard
          title="Fuga de agua"
          description="Hay una fuga en el piso 2"
          campus="San Juan"
          location="Edificio A"
          status="Pendiente"
          reporterName="Pedro"
          reportTime="Hace 5m"
          onStatusChangeClick={onStatusChangeClick}
        />,
      );

      expect(screen.getByText('Fuga de agua')).toBeInTheDocument();
      expect(screen.getByText(/"Hay una fuga en el piso 2"/i)).toBeInTheDocument();

      const changeBtn = screen.getByRole('button', { name: /cambiar estado/i });
      fireEvent.click(changeBtn);
      expect(onStatusChangeClick).toHaveBeenCalled();
    });
  });

  describe('PublishReportCard', () => {
    it('fills form and publishes incident report', () => {
      const onPublish = vi.fn();
      const onDiscard = vi.fn();

      renderWithQueryClient(
        <PublishReportCard onPublish={onPublish} onDiscard={onDiscard} />,
      );

      expect(screen.getByText('PUBLICAR REPORTE')).toBeInTheDocument();

      const titleInput = screen.getByPlaceholderText('TÍTULO DEL REPORTE');
      const descInput = screen.getByPlaceholderText('DESCRIPCIÓN DEL INCIDENTE');

      fireEvent.change(titleInput, { target: { value: 'Ventana rota' } });
      fireEvent.change(descInput, { target: { value: 'Sala 101 ventana trizada' } });

      const publishBtn = screen.getByRole('button', { name: /publicar/i });
      fireEvent.click(publishBtn);

      expect(onPublish).toHaveBeenCalledWith({
        title: 'Ventana rota',
        description: 'Sala 101 ventana trizada',
        structureId: 's1',
        files: [],
      });
    });
  });

  describe('ChangeReportStatusModal', () => {
    it('allows changing report status and saving', () => {
      const onClose = vi.fn();
      const mockReport: ReportDto = {
        id: 'r1',
        ticketType: TicketStatus.Pending,
        structureRefId: 's1',
        reportedAt: '2026-11-03',
        complaintDetails: {
          title: 'Gotera',
          description: 'Gotera en techo',
        },
      } as unknown as ReportDto;

      renderWithQueryClient(
        <ChangeReportStatusModal
          isOpen={true}
          onClose={onClose}
          report={mockReport}
          locationName="Edificio A"
        />,
      );

      expect(screen.getByText(/cambiar estado del reporte/i)).toBeInTheDocument();
      expect(screen.getByText(/Gotera/)).toBeInTheDocument();

      const resolvedOption = screen.getByText('RESUELTO');
      fireEvent.click(resolvedOption);

      const saveBtn = screen.getByRole('button', { name: /guardar estado/i });
      fireEvent.click(saveBtn);

      expect(mockUpdateStatusMutate).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'r1',
          status: TicketStatus.Resolved,
        }),
        expect.any(Object),
      );
    });
  });
});
