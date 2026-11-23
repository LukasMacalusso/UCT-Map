import { useMemo, useState, type FormEvent } from 'react';
import { ModalOverlay } from '../../components/layout/ModalOverlay';
import { Button } from '../../components/ui/Button';
import { Input } from '../../components/ui/Input';
import { Select } from '../../components/ui/Select';
import { useCreateOfficeHour } from '../../hooks/useSchedule';
import type { DayOfWeekName } from '../../dtos/schedule/OfficeHourDto';
import type { StructureDto } from '../../dtos/campus/StructureDto';
import { DAY_INDEX, DAY_LABELS, timeToMinutes } from '../../utils/schedule';
import CrossIcon from '../../assets/svg/icons/icon_cross.svg?react';

const DAY_ORDER: DayOfWeekName[] = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const DAY_OPTIONS = DAY_ORDER.map((value) => ({
  value,
  label: DAY_LABELS[DAY_INDEX[value]],
}));

const DEFAULT_START = '09:00';
const DEFAULT_END = '10:00';

const toTimeOnly = (value: string): string =>
  `${value.slice(0, 5).padStart(5, '0')}:00`;

interface CreateOfficeHourModalProps {
  isOpen: boolean;
  onClose: () => void;
  teacherRefId?: string;
  structures: StructureDto[];
}

export const CreateOfficeHourModal = ({
  isOpen,
  onClose,
  teacherRefId,
  structures,
}: CreateOfficeHourModalProps) => {
  const [dayOfWeek, setDayOfWeek] = useState<DayOfWeekName>('Monday');
  const [startTime, setStartTime] = useState(DEFAULT_START);
  const [endTime, setEndTime] = useState(DEFAULT_END);
  const [structureRefId, setStructureRefId] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);
  const createOfficeHour = useCreateOfficeHour();

  const resetForm = () => {
    setDayOfWeek('Monday');
    setStartTime(DEFAULT_START);
    setEndTime(DEFAULT_END);
    setStructureRefId('');
    setValidationError(null);
  };

  const structureOptions = useMemo(
    () => [
      { value: '', label: 'Sin ubicación' },
      ...structures.map((structure) => ({
        value: structure.id,
        label: structure.name,
      })),
    ],
    [structures],
  );

  const handleClose = () => {
    createOfficeHour.reset();
    resetForm();
    onClose();
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setValidationError(null);

    if (!teacherRefId) {
      setValidationError('No se pudo identificar al profesor.');
      return;
    }

    if (!startTime || !endTime) {
      setValidationError('Debes indicar la hora de inicio y de fin.');
      return;
    }

    if (timeToMinutes(endTime) <= timeToMinutes(startTime)) {
      setValidationError('La hora de fin debe ser posterior a la hora de inicio.');
      return;
    }

    createOfficeHour.mutate(
      {
        teacherRefId,
        structureRefId: structureRefId || null,
        dayOfWeek,
        startTime: toTimeOnly(startTime),
        endTime: toTimeOnly(endTime),
      },
      { onSuccess: handleClose },
    );
  };

  const errorMessage = validationError ?? createOfficeHour.error?.message ?? null;

  return (
    <ModalOverlay isOpen={isOpen} onClose={handleClose}>
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl flex flex-col gap-4"
      >
        <div className="flex items-center justify-between pb-3 border-b border-gray-100">
          <div className="flex flex-col min-w-0 pr-2">
            <h3 className="text-lg font-extrabold text-gray-800 uppercase tracking-tight">
              Nuevo Bloque de Atención
            </h3>
            <span className="text-xs text-gray-500 font-medium">
              Define el día y la franja horaria.
            </span>
          </div>
          <button
            type="button"
            onClick={handleClose}
            className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-700 transition-colors cursor-pointer shrink-0"
            title="Cerrar"
          >
            <CrossIcon className="w-4 h-4" />
          </button>
        </div>

        <div className="flex flex-col gap-3">
          <Select
            label="Día"
            labelColor="text-gray-700"
            options={DAY_OPTIONS}
            value={dayOfWeek}
            onChange={(value) => setDayOfWeek(value as DayOfWeekName)}
          />

          <div className="grid grid-cols-2 gap-3">
            <Input
              label="Hora de inicio"
              aria-label="Hora de inicio"
              type="time"
              step={60}
              value={startTime}
              onChange={(event) => setStartTime(event.target.value)}
            />
            <Input
              label="Hora de fin"
              aria-label="Hora de fin"
              type="time"
              step={60}
              value={endTime}
              onChange={(event) => setEndTime(event.target.value)}
            />
          </div>

          <Select
            label="Ubicación"
            labelColor="text-gray-700"
            options={structureOptions}
            value={structureRefId}
            onChange={setStructureRefId}
          />
        </div>

        {!teacherRefId && (
          <span className="text-xs text-page-red font-semibold">
            No se pudo identificar al profesor. Vuelve a iniciar sesión.
          </span>
        )}

        {errorMessage && (
          <span className="text-xs text-page-red font-semibold">{errorMessage}</span>
        )}

        <div className="flex gap-2 pt-2 border-t border-gray-100">
          <Button
            type="submit"
            color="blue"
            className="flex-1 !w-auto"
            disabled={createOfficeHour.isPending || !teacherRefId}
          >
            {createOfficeHour.isPending ? 'Guardando...' : 'Guardar bloque'}
          </Button>
          <Button
            type="button"
            variant="outline"
            color="gray"
            className="!w-auto px-5"
            onClick={handleClose}
            disabled={createOfficeHour.isPending}
          >
            Cancelar
          </Button>
        </div>
      </form>
    </ModalOverlay>
  );
};
