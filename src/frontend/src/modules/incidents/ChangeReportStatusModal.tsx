import React, { useState } from 'react';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { Button } from '../../components/ui/Button';
import { Tag } from '../../components/ui/Tag';
import {
  TicketStatus,
  TICKET_STATUS_LABELS,
  TICKET_STATUS_COLORS,
} from '../../constants/ticketStatus';
import { useUpdateReportStatus } from '../../hooks/useReports';
import { useUiState } from '../../states/uiState';
import type { ReportDto } from '../../dtos/incident/reports/ReportDto';
import CheckIcon from '../../assets/svg/icons/icon_check.svg?react';
import CrossIcon from '../../assets/svg/icons/icon_cross.svg?react';

interface ChangeReportStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  report: ReportDto | null;
  locationName?: string;
}

const TICKET_STATUS_OPTIONS: {
  value: TicketStatus;
  desc: string;
}[] = [
  {
    value: TicketStatus.Pending,
    desc: 'Reporte nuevo en espera de asignación técnica o revisión.',
  },
  {
    value: TicketStatus.InProcess,
    desc: 'Cuadrilla técnica asignada o trabajos de reparación en curso.',
  },
  {
    value: TicketStatus.Resolved,
    desc: 'Incidente solucionado e infraestructura operativa normal.',
  },
  {
    value: TicketStatus.Dismissed,
    desc: 'Reporte duplicado, resuelto previamente o descartado.',
  },
];

export const ChangeReportStatusModal: React.FC<ChangeReportStatusModalProps> = ({
  isOpen,
  onClose,
  report,
  locationName,
}) => {
  const [selectedStatus, setSelectedStatus] = useState<TicketStatus>(
    report?.ticketType ?? TicketStatus.Pending,
  );
  const [prevReport, setPrevReport] = useState(report);

  if (report !== prevReport) {
    setPrevReport(report);
    if (report) {
      setSelectedStatus(report.ticketType);
    }
  }

  const updateStatus = useUpdateReportStatus();
  const notifyEditor = useUiState((state) => state.notifyEditor);

  if (!report) return null;

  const title = report.complaintDetails?.title || 'Reporte de incidente';

  const handleSave = () => {
    updateStatus.mutate(
      {
        id: report.id,
        status: selectedStatus,
      },
      {
        onSuccess: () => {
          const statusLabel = TICKET_STATUS_LABELS[selectedStatus];
          notifyEditor(`Estado del reporte actualizado a ${statusLabel}.`);
          onClose();
        },
      },
    );
  };

  const isUnchanged = selectedStatus === report.ticketType;

  return (
    <ModalOverlay isOpen={isOpen} onClose={onClose}>
      <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-gray-100">
          <div className="flex flex-col min-w-0 pr-2">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Cambiar Estado del Reporte
            </h3>
            <span className="text-xs text-gray-500 font-medium truncate">
              {title} {locationName ? `• ${locationName}` : ''}
            </span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors cursor-pointer shrink-0"
            title="Cerrar"
          >
            <CrossIcon className="w-4 h-4" />
          </button>
        </div>

        {/* Ticket Status Options */}
        <div className="flex flex-col gap-2.5">
          <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">
            Estado del Ticket
          </label>
          <div className="flex flex-col gap-2">
            {TICKET_STATUS_OPTIONS.map((opt) => {
              const isSelected = selectedStatus === opt.value;
              const label = TICKET_STATUS_LABELS[opt.value];
              const color = TICKET_STATUS_COLORS[opt.value];

              return (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => setSelectedStatus(opt.value)}
                  className={`p-3 rounded-2xl border text-left flex items-center justify-between transition-all cursor-pointer ${
                    isSelected
                      ? 'border-page-blue bg-blue-50/70 ring-2 ring-page-blue/20 shadow-xs'
                      : 'border-gray-200 bg-white hover:bg-gray-50'
                  }`}
                >
                  <div className="flex flex-col gap-1 pr-2">
                    <div className="flex items-center gap-2">
                      <Tag
                        label={label}
                        color={color}
                        className="!text-xs !px-2.5 !py-0.5 font-bold uppercase"
                      />
                    </div>
                    <span className="text-xs text-gray-500 leading-snug">
                      {opt.desc}
                    </span>
                  </div>
                  {isSelected && (
                    <div className="w-6 h-6 rounded-full bg-page-blue text-white flex items-center justify-center shrink-0">
                      <CheckIcon className="w-3.5 h-3.5" />
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>

        {/* Error notification */}
        {updateStatus.isError && (
          <span className="text-xs text-page-red font-semibold">
            {updateStatus.error?.message || 'Error al actualizar el estado.'}
          </span>
        )}

        {/* Action Buttons */}
        <div className="flex gap-2 pt-2 border-t border-gray-100">
          <Button
            color="blue"
            className="flex-1 !w-auto"
            onClick={handleSave}
            disabled={updateStatus.isPending || isUnchanged}
          >
            {updateStatus.isPending ? 'Guardando...' : 'Guardar estado'}
          </Button>
          <Button
            variant="outline"
            color="gray"
            className="!w-auto px-5"
            onClick={onClose}
          >
            Cancelar
          </Button>
        </div>
      </div>
    </ModalOverlay>
  );
};
