import { useMemo, useState } from 'react';
import { Panel } from '../components/layout/Panel';
import { ModalOverlay } from '../components/layout/ModalOverlay';
import { Select } from '../components/ui/Select';
import { Button } from '../components/ui/Button';
import { SquareButton } from '../components/ui/SquareButton';
import { TimedActionCard } from '../components/ui/TimedActionCard';
import { EmptyState } from '../components/ui/EmptyState';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { IconText } from '../components/ui/IconText';
import {
  useTeacherWorkload,
  useDeleteOfficeHour,
  useCancelMeeting,
} from '../hooks/useSchedule';
import { useStructures } from '../hooks/useCampus';
import { useUsers } from '../hooks/useUsers';
import { useAuthState } from '../states/authState';
import { MeetingStatusSelect } from '../modules/schedule/MeetingStatusSelect';
import { CreateOfficeHourModal } from '../modules/schedule/CreateOfficeHourModal';
import type { OfficeHourDto } from '../dtos/schedule/OfficeHourDto';
import type { MeetingDto } from '../dtos/schedule/MeetingDto';
import {
  addDays,
  formatClock,
  formatLongDate,
  formatOfficeHour,
  parseScheduleDate,
  sortOfficeHours,
  startOfDay,
} from '../utils/schedule';

import CalendarIcon from '../assets/svg/icons/icon_calendar.svg?react';
import ClockIcon from '../assets/svg/icons/icon_clock.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import UserIcon from '../assets/svg/icons/icon_user.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';
import RefreshIcon from '../assets/svg/icons/icon_repeat.svg?react';
import PlusIcon from '../assets/svg/icons/icon_plus.svg?react';
import PencilIcon from '../assets/svg/icons/icon_pencil.svg?react';
import TrashIcon from '../assets/svg/icons/icon_trash.svg?react';

const RANGE_OPTIONS = [
  { value: '7', label: 'Próximos 7 días' },
  { value: '14', label: 'Próximos 14 días' },
  { value: '30', label: 'Próximos 30 días' },
];

const STATUS_OPTIONS = [
  { value: 'todos', label: 'Todos los estados' },
  { value: 'Pending', label: 'Pendiente' },
  { value: 'Confirmed', label: 'Confirmada' },
  { value: 'Completed', label: 'Completada' },
  { value: 'Cancelled', label: 'Cancelada' },
];

export const ScheduleView = () => {
  const user = useAuthState((state) => state.user);
  const [daysAhead, setDaysAhead] = useState('14');
  const [statusFilter, setStatusFilter] = useState('todos');
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editingOfficeHour, setEditingOfficeHour] = useState<OfficeHourDto | null>(null);
  const [deletingOfficeHour, setDeletingOfficeHour] = useState<OfficeHourDto | null>(null);
  const [cancellingMeeting, setCancellingMeeting] = useState<MeetingDto | null>(null);

  const deleteOfficeHour = useDeleteOfficeHour();
  const cancelMeeting = useCancelMeeting();

  const dateRange = useMemo(() => {
    const fromDate = startOfDay(new Date());
    const toDate = addDays(fromDate, Number(daysAhead) || 14);
    return {
      from: fromDate.toISOString(),
      to: toDate.toISOString(),
    };
  }, [daysAhead]);

  const {
    data: workload,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = useTeacherWorkload(user?.id, dateRange.from, dateRange.to);

  const { data: structures = [] } = useStructures();
  const { data: users = [] } = useUsers();

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const usersById = useMemo(
    () => new Map(users.map((item) => [item.id, item])),
    [users],
  );

  const sortedOfficeHours = useMemo(
    () => sortOfficeHours(workload?.officeHours ?? []),
    [workload?.officeHours],
  );

  const filteredMeetings = useMemo(() => {
    const list = workload?.meetings ?? [];
    return [...list]
      .filter((meeting) => statusFilter === 'todos' || meeting.status === statusFilter)
      .sort(
        (a, b) =>
          parseScheduleDate(a.scheduledAt).getTime() -
          parseScheduleDate(b.scheduledAt).getTime(),
      );
  }, [workload?.meetings, statusFilter]);

  const weeklyHoursLabel = useMemo(() => {
    const mins = workload?.weeklyOfficeHourMinutes ?? 0;
    const hours = Math.floor(mins / 60);
    const remMins = mins % 60;
    if (hours === 0) return `${remMins} min`;
    if (remMins === 0) return `${hours} hrs`;
    return `${hours} h ${remMins} min`;
  }, [workload?.weeklyOfficeHourMinutes]);

  const scheduledMinutesInPeriod = useMemo(
    () =>
      (workload?.meetings ?? [])
        .filter((meeting) => meeting.status !== 'Cancelled')
        .reduce((acc, meeting) => acc + meeting.durationMinutes, 0),
    [workload?.meetings],
  );

  const isRefreshing = isFetching && !isLoading;

  return (
    <div className="p-6 h-full min-h-screen bg-transparent flex flex-col gap-6 overflow-hidden">
      {/* Top Controls */}
      <div className="py-2 px-4 flex flex-wrap items-end justify-end gap-4 flex-shrink-0">
        <div className="w-64">
          <Select
            label="Rango de fechas"
            options={RANGE_OPTIONS}
            value={daysAhead}
            onChange={setDaysAhead}
            icon={<CalendarIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>

        <div className="w-64">
          <Select
            label="Estado de reunión"
            options={STATUS_OPTIONS}
            value={statusFilter}
            onChange={setStatusFilter}
            icon={<FilterIcon className="w-5 h-5 text-gray-700" />}
          />
        </div>

        <Button
          variant="solid"
          color="blue"
          size="lg"
          className="!w-auto flex items-center gap-2"
          onClick={() => refetch()}
          disabled={isRefreshing || isLoading}
        >
          <RefreshIcon className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          Actualizar
        </Button>
      </div>

      {isLoading ? (
        <div className="flex-1 flex items-center justify-center p-12">
          <LoadingSpinner size="lg" text="Cargando carga académica y reuniones..." />
        </div>
      ) : isError ? (
        <div className="flex-1 flex items-center justify-center p-12">
          <EmptyState
            message={error?.message ?? 'No se pudo cargar la información de tu horario.'}
          />
        </div>
      ) : (
        <div className="flex-1 flex flex-col gap-6 w-full min-h-0">
          {/* Summary Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 w-full flex-shrink-0">
            <Panel
              color="white"
              outerClassName="!w-full"
              innerClassName="p-6 flex flex-col gap-2"
            >
              <span className="text-xs font-bold text-black uppercase tracking-wider">
                Atención Semanal Configurada
              </span>
              <span className="text-3xl font-black text-black">{weeklyHoursLabel}</span>
              <span className="text-sm text-black">
                {sortedOfficeHours.length}{' '}
                {sortedOfficeHours.length === 1 ? 'bloque activo' : 'bloques activos'}
              </span>
            </Panel>

            <Panel
              color="white"
              outerClassName="!w-full"
              innerClassName="p-6 flex flex-col gap-2"
            >
              <span className="text-xs font-bold text-black uppercase tracking-wider">
                Reuniones en el Período
              </span>
              <span className="text-3xl font-black text-black">
                {workload?.meetingCount ?? 0}
              </span>
              <span className="text-sm text-black">Próximos {daysAhead} días</span>
            </Panel>

            <Panel
              color="white"
              outerClassName="!w-full"
              innerClassName="p-6 flex flex-col gap-2"
            >
              <span className="text-xs font-bold text-black uppercase tracking-wider">
                Tiempo Reservado
              </span>
              <span className="text-3xl font-black text-black">
                {scheduledMinutesInPeriod} min
              </span>
              <span className="text-sm text-black">Excluyendo canceladas</span>
            </Panel>
          </div>

          {/* Office Hours & Scheduled Meetings */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 flex-1 min-h-0 w-full items-stretch">
            {/* Weekly Office Hours */}
            <Panel
              color="white"
              outerClassName="!w-full !h-full min-h-0"
              innerClassName="p-6 flex flex-col gap-4 h-full min-h-0"
            >
              <div className="flex items-center justify-between gap-2 flex-wrap flex-shrink-0">
                <h2 className="text-lg font-bold text-gray-800 uppercase tracking-wide flex items-center gap-2">
                  <ClockIcon className="w-5 h-5 text-page-blue" />
                  Mis Bloques de Atención
                </h2>
                <Button
                  type="button"
                  color="blue"
                  size="sm"
                  className="!w-auto flex items-center gap-1.5"
                  onClick={() => {
                    setEditingOfficeHour(null);
                    setIsCreateOpen(true);
                  }}
                  disabled={!user?.id}
                >
                  <PlusIcon className="w-4 h-4" />
                  Agregar
                </Button>
              </div>

              <div className="bg-page-gray-light p-4 rounded-xl flex flex-col gap-3 flex-1 min-h-0 overflow-y-auto">
                {sortedOfficeHours.length === 0 ? (
                  <div className="flex-1 flex items-center justify-center p-6 text-sm text-gray-500 text-center">
                    No tienes bloques de atención semanal registrados.
                  </div>
                ) : (
                  sortedOfficeHours.map((block) => {
                    const buildingName =
                      (block.structureRefId && structureNames.get(block.structureRefId)) ||
                      'Ubicación por confirmar';

                    return (
                      <div
                        key={block.id}
                        className="bg-white p-4 rounded-xl shadow-sm flex items-center justify-between gap-3 border border-gray-100 flex-shrink-0"
                      >
                        <div className="flex flex-col gap-1.5 min-w-0">
                          <span className="font-bold text-gray-800 text-sm">
                            {formatOfficeHour(block)}
                          </span>
                          <IconText
                            icon={<BuildingIcon className="w-4 h-4 text-page-blue" />}
                            text={buildingName}
                            className="!text-xs text-gray-600"
                          />
                        </div>

                        <div className="flex items-center gap-1.5 flex-shrink-0">
                          <SquareButton
                            type="button"
                            title="Editar bloque"
                            className="!w-8 !h-8 !rounded-lg shrink-0 !shadow-none border border-gray-200 hover:border-page-blue transition-colors"
                            onClick={() => {
                              setEditingOfficeHour(block);
                              setIsCreateOpen(true);
                            }}
                          >
                            <PencilIcon className="w-3.5 h-3.5 pointer-events-none text-page-blue" />
                          </SquareButton>
                          <SquareButton
                            type="button"
                            title="Eliminar bloque"
                            className="!w-8 !h-8 !rounded-lg shrink-0 !shadow-none border border-gray-200 hover:border-page-red transition-colors"
                            onClick={() => setDeletingOfficeHour(block)}
                          >
                            <TrashIcon className="w-3.5 h-3.5 pointer-events-none text-page-red" />
                          </SquareButton>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </Panel>

            {/* Scheduled Meetings */}
            <Panel
              color="white"
              outerClassName="!w-full !h-full lg:col-span-2 min-h-0"
              innerClassName="p-6 flex flex-col gap-4 h-full min-h-0"
            >
              <div className="flex items-center flex-shrink-0">
                <h2 className="text-lg font-bold text-gray-800 uppercase tracking-wide flex items-center gap-2">
                  <CalendarIcon className="w-5 h-5 text-page-blue" />
                  Reuniones Agendadas
                </h2>
              </div>

              <div className="bg-page-gray-light p-4 rounded-xl flex flex-col gap-3 flex-1 min-h-0 overflow-y-auto">
                {filteredMeetings.length === 0 ? (
                  <div className="flex-1 flex items-center justify-center p-8 text-sm text-gray-500 text-center">
                    No hay reuniones agendadas que coincidan con el filtro seleccionado.
                  </div>
                ) : (
                  filteredMeetings.map((meeting) => {
                    const start = parseScheduleDate(meeting.scheduledAt);
                    const end = new Date(start.getTime() + meeting.durationMinutes * 60000);
                    const student = usersById.get(meeting.studentRefId);
                    const locationName =
                      (meeting.structureRefId && structureNames.get(meeting.structureRefId)) ||
                      'Oficina docente';

                    return (
                      <div
                        key={meeting.id}
                        className="bg-white p-4 rounded-xl shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4 border border-gray-100 flex-shrink-0"
                      >
                        <div className="flex flex-col gap-1.5 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="font-bold text-gray-800 text-base">
                              {formatLongDate(start)}
                            </span>
                            <span className="text-sm font-semibold text-page-blue">
                              {formatClock(start)} - {formatClock(end)} ({meeting.durationMinutes} min)
                            </span>
                          </div>

                          <div className="flex flex-wrap items-center gap-4 text-xs text-gray-600">
                            <IconText
                              icon={<UserIcon className="w-4 h-4 text-gray-700" />}
                              text={
                                student
                                  ? `${student.name} (${student.email})`
                                  : `Estudiante (${meeting.studentRefId.slice(0, 8)})`
                              }
                              className="!text-xs"
                            />
                            <IconText
                              icon={<BuildingIcon className="w-4 h-4 text-gray-700" />}
                              text={locationName}
                              className="!text-xs"
                            />
                          </div>
                        </div>

                        <div className="flex items-center gap-2 flex-wrap flex-shrink-0 self-start sm:self-center">
                          <MeetingStatusSelect
                            meeting={meeting}
                            isTeacher={user?.id === meeting.teacherRefId}
                            isStudent={user?.id === meeting.studentRefId}
                          />
                          {(meeting.status === 'Pending' || meeting.status === 'Confirmed') && (
                            <SquareButton
                              type="button"
                              title="Cancelar reunión"
                              className="!w-9 !h-9 !rounded-xl shrink-0 !shadow-none border border-gray-200 hover:border-page-red transition-colors"
                              onClick={() => setCancellingMeeting(meeting)}
                            >
                              <TrashIcon className="w-4 h-4 pointer-events-none text-page-red" />
                            </SquareButton>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </Panel>
          </div>
        </div>
      )}

      <CreateOfficeHourModal
        isOpen={isCreateOpen}
        onClose={() => {
          setIsCreateOpen(false);
          setEditingOfficeHour(null);
        }}
        teacherRefId={user?.id}
        structures={structures}
        editingOfficeHour={editingOfficeHour}
      />

      <ModalOverlay isOpen={!!deletingOfficeHour} onClose={() => setDeletingOfficeHour(null)}>
        <TimedActionCard
          title="Eliminar bloque de atención"
          description={`¿Estás seguro de que deseas eliminar el bloque "${
            deletingOfficeHour ? formatOfficeHour(deletingOfficeHour) : ''
          }"? Las reuniones pendientes o confirmadas fuera del nuevo horario serán canceladas.`}
          initialDurationMs={1500}
          options={[
            {
              label: 'Cancelar',
              color: 'gray',
              onClick: () => setDeletingOfficeHour(null),
            },
            {
              label: 'Sí, eliminar',
              color: 'red',
              onClick: () => {
                if (!deletingOfficeHour?.id) return;
                deleteOfficeHour?.mutate?.(deletingOfficeHour.id, {
                  onSuccess: () => setDeletingOfficeHour(null),
                });
              },
            },
          ]}
        />
      </ModalOverlay>

      <ModalOverlay isOpen={!!cancellingMeeting} onClose={() => setCancellingMeeting(null)}>
        <TimedActionCard
          title="Cancelar reunión"
          description="¿Estás seguro de que deseas cancelar esta reunión agendada?"
          initialDurationMs={1500}
          options={[
            {
              label: 'Volver',
              color: 'gray',
              onClick: () => setCancellingMeeting(null),
            },
            {
              label: 'Sí, cancelar reunión',
              color: 'red',
              onClick: () => {
                if (!cancellingMeeting?.id) return;
                cancelMeeting?.mutate?.(cancellingMeeting.id, {
                  onSuccess: () => setCancellingMeeting(null),
                });
              },
            },
          ]}
        />
      </ModalOverlay>
    </div>
  );
};

export const TeacherView = ScheduleView;
