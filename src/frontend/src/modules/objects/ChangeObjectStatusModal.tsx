import React, { useState } from 'react';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { Button } from '../../components/ui/Button';
import { Tag } from '../../components/ui/Tag';
import {
  LostObjectStatus,
  LOST_OBJECT_STATUS_LABELS,
  LOST_OBJECT_STATUS_COLORS,
} from '../../constants/lostObjectsStatus';
import { useUpdateLostObjectStatus } from '../../hooks/useLostObjects';
import { useUiState } from '../../states/uiState';
import type { LostObjectDto } from '../../dtos/incident/objects/LostObjectDto';
import CheckIcon from '../../assets/svg/icons/icon_check.svg?react';
import CrossIcon from '../../assets/svg/icons/icon_cross.svg?react';

interface ChangeObjectStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
  lostObject: LostObjectDto | null;
}

const STATUS_OPTIONS: {
  value: LostObjectStatus;
  desc: string;
}[] = [
  {
    value: LostObjectStatus.Pending,
    desc: 'Objeto reportado en espera de revisión o recepción en custodia.',
  },
  {
    value: LostObjectStatus.InProcess,
    desc: 'En custodia o en proceso de verificación con el dueño.',
  },
  {
    value: LostObjectStatus.Resolved,
    desc: 'Objeto devuelto con éxito a su propietario legítimo.',
  },
  {
    value: LostObjectStatus.Canceled,
    desc: 'Reporte cancelado, duplicado o descartado.',
  },
];

export const ChangeObjectStatusModal: React.FC<ChangeObjectStatusModalProps> = ({
  isOpen,
  onClose,
  lostObject,
}) => {
  const [selectedStatus, setSelectedStatus] = useState<LostObjectStatus>(
    lostObject?.status ?? LostObjectStatus.Pending,
  );
  const [prevLostObject, setPrevLostObject] = useState(lostObject);

  if (lostObject !== prevLostObject) {
    setPrevLostObject(lostObject);
    if (lostObject) {
      setSelectedStatus(lostObject.status);
    }
  }

  const updateStatus = useUpdateLostObjectStatus();
  const notifyEditor = useUiState((state) => state.notifyEditor);

  if (!lostObject) return null;

  const targetId = lostObject.id || lostObject.lostObjectId;

  const handleSave = () => {
    if (!targetId) return;

    updateStatus.mutate(
      { id: targetId, status: selectedStatus },
      {
        onSuccess: () => {
          const statusLabel = LOST_OBJECT_STATUS_LABELS[selectedStatus];
          notifyEditor(`Estado de "${lostObject.title}" actualizado a ${statusLabel}.`);
          onClose();
        },
      },
    );
  };

  return (
    <ModalOverlay isOpen={isOpen} onClose={onClose}>
      <div className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4">
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-gray-100">
          <div className="flex flex-col min-w-0 pr-2">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Cambiar Estado del Objeto
            </h3>
            <span className="text-xs text-gray-500 font-medium truncate">
              {lostObject.title}
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

        {/* Status Options List */}
        <div className="flex flex-col gap-2.5">
          <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">
            Seleccionar nuevo estado
          </label>
          <div className="flex flex-col gap-2">
            {STATUS_OPTIONS.map((opt) => {
              const isSelected = selectedStatus === opt.value;
              const label = LOST_OBJECT_STATUS_LABELS[opt.value];
              const color = LOST_OBJECT_STATUS_COLORS[opt.value];

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
            disabled={updateStatus.isPending || selectedStatus === lostObject.status}
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
