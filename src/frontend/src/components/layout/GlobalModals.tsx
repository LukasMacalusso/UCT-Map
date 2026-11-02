import { useMemo } from 'react';
import { useUiState } from '../../states/uiState';
import { useAuthState } from '../../states/authState';
import { ModalOverlay } from './ModalOverlay';
import { TimedActionCard } from '../ui/TimedActionCard';
import {
  UserProfilePanel,
  type UserProfileMeetingItem,
} from '../../modules/global/UserProfilePanel';
import { useNavigate } from 'react-router-dom';
import { useReports } from '../../hooks/useReports';
import { useLostObjectsByIds } from '../../hooks/useLostObjects';
import { useAllMeetings, useUpdateMeetingStatus } from '../../hooks/useSchedule';
import { useStructures } from '../../hooks/useCampus';
import { useUsers } from '../../hooks/useUsers';
import {
  LOST_OBJECT_STATUS_COLORS,
  LOST_OBJECT_STATUS_LABELS,
} from '../../constants/lostObjectsStatus';
import {
  TICKET_STATUS_COLORS,
  TICKET_STATUS_LABELS,
} from '../../constants/ticketStatus';
import { formatRelativeTime } from '../../utils/date';
import {
  formatClock,
  formatLongDate,
  MEETING_STATUS_COLORS,
  MEETING_STATUS_LABELS,
  parseScheduleDate,
} from '../../utils/schedule';
import type { ObjectReportCardProps } from '../../modules/objects/ObjectReportCard';
import type { IncidentCardProps } from '../../modules/incidents/IncidentCard';

export const GlobalModals = () => {
  const activePanel = useUiState((state) => state.activePanel);
  const closePanel = useUiState((state) => state.closePanel);
  const user = useAuthState((state) => state.user);
  const logout = useAuthState((state) => state.logout);
  const navigate = useNavigate();
  const updateMeetingStatus = useUpdateMeetingStatus();

  const isProfileOpen = activePanel === 'userProfile' && !!user;

  const { data: structures = [] } = useStructures(undefined, isProfileOpen);
  const { data: users = [] } = useUsers();

  const reportParams = useMemo(
    () => ({
      userRefId: user?.id,
      sortBy: 'ReportedAt' as const,
      descending: true,
      page: 1,
      pageSize: 10,
    }),
    [user?.id],
  );

  const { data: reportsPage } = useReports(reportParams, isProfileOpen);

  const userLostObjectIds = useMemo(
    () =>
      (reportsPage?.items ?? [])
        .filter((report) => report.userRefId === user?.id && Boolean(report.lostObjectId))
        .map((report) => report.lostObjectId!),
    [reportsPage?.items, user?.id],
  );

  const { data: userLostObjects = [] } = useLostObjectsByIds(userLostObjectIds, isProfileOpen);
  const { data: allMeetings = [] } = useAllMeetings(isProfileOpen);

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const usersById = useMemo(
    () => new Map(users.map((item) => [item.id, item])),
    [users],
  );

  const incidentReports = useMemo<IncidentCardProps[]>(() => {
    if (!user || !reportsPage?.items) return [];
    return reportsPage.items
      .filter((report) => report.userRefId === user.id && report.complaintDetails != null)
      .map((report) => ({
        location:
          (report.structureRefId && structureNames.get(report.structureRefId)) ||
          'Sin ubicación',
        status: TICKET_STATUS_LABELS[report.ticketType] ?? 'SIN ESTADO',
        statusColor: TICKET_STATUS_COLORS[report.ticketType] ?? 'gray',
        title: report.complaintDetails?.title ?? 'Reporte sin título',
        reporterName: user.name,
        reportTime: formatRelativeTime(report.reportedAt),
        reporterAvatar: user.avatar,
        description: report.complaintDetails?.description ?? 'Sin descripción',
      }));
  }, [user, reportsPage, structureNames]);

  const objectReports = useMemo<ObjectReportCardProps[]>(() => {
    if (!user) return [];
    return userLostObjects.map((lostObject) => ({
      title: lostObject.title,
      status: LOST_OBJECT_STATUS_LABELS[lostObject.status],
      statusColor: LOST_OBJECT_STATUS_COLORS[lostObject.status],
      photoUrl: lostObject.photoUrl,
      building: structureNames.get(lostObject.structureId) ?? 'Sin ubicación',
      actions: [
        {
          title: `Reportado por ${user.name}`,
          subtitle: formatRelativeTime(lostObject.reportedAt),
          avatarSrc: user.avatar,
        },
      ],
    }));
  }, [user, userLostObjects, structureNames]);

  const requestedMeetings = useMemo<UserProfileMeetingItem[]>(() => {
    if (!user) return [];
    return allMeetings
      .filter((meeting) => meeting.studentRefId === user.id)
      .sort(
        (a, b) =>
          parseScheduleDate(b.scheduledAt).getTime() -
          parseScheduleDate(a.scheduledAt).getTime(),
      )
      .map((meeting) => {
        const start = parseScheduleDate(meeting.scheduledAt);
        const end = new Date(start.getTime() + meeting.durationMinutes * 60000);
        const teacher = usersById.get(meeting.teacherRefId);
        const location =
          (meeting.structureRefId && structureNames.get(meeting.structureRefId)) ||
          'Oficina docente';

        return {
          id: meeting.id,
          teacherName: teacher?.name ?? 'Profesor',
          teacherEmail: teacher?.email,
          location,
          dateLabel: formatLongDate(start),
          timeLabel: `${formatClock(start)} - ${formatClock(end)} (${meeting.durationMinutes} min)`,
          statusLabel:
            MEETING_STATUS_LABELS[meeting.status] ?? meeting.status.toUpperCase(),
          statusColor: MEETING_STATUS_COLORS[meeting.status] ?? 'blue',
          canCancel: meeting.status === 'Pending' || meeting.status === 'Confirmed',
        };
      });
  }, [user, allMeetings, usersById, structureNames]);

  const admissionYear = useMemo(() => {
    if (!user?.registeredAt) return undefined;
    const year = new Date(user.registeredAt).getFullYear();
    return Number.isNaN(year) ? undefined : String(year);
  }, [user?.registeredAt]);

  const handleLogout = () => {
    logout();
    closePanel();
    navigate('/login');
  };

  return (
    <>
      <ModalOverlay
        isOpen={activePanel === 'userProfile'}
        onClose={closePanel}
      >
        {user && (
          <UserProfilePanel
            name={user.name}
            role={user.role}
            admissionYear={admissionYear}
            email={user.email}
            photoUrl={user.avatar}
            onClose={closePanel}
            onLogout={handleLogout}
            objectReports={objectReports}
            incidentReports={incidentReports}
            requestedMeetings={requestedMeetings}
            onCancelMeeting={(meetingId) =>
              updateMeetingStatus.mutate({ id: meetingId, status: 'Cancelled' })
            }
            isCancellingMeeting={updateMeetingStatus.isPending}
          />
        )}
      </ModalOverlay>

      <ModalOverlay 
        isOpen={activePanel === 'saveMapChanges'} 
        onClose={closePanel}
      >
        <TimedActionCard
          title="Confirmar Cambios"
          description="Estos cambios serán públicos y visibles para todos los estudiantes. Por favor, revisa tus modificaciones antes de continuar."
          initialDurationMs={3000}
          options={[
            {
              label: "Cancelar",
              color: "gray",
              onClick: closePanel
            },
            {
              label: "Publicar Mapa",
              color: "green",
              onClick: () => {
                console.log("Mapa guardado exitosamente");
                closePanel();
              }
            }
          ]}
        />
      </ModalOverlay>

      <ModalOverlay 
        isOpen={activePanel === 'discardMapChanges'} 
        onClose={closePanel}
      >
        <TimedActionCard
          title="Descartar Cambios"
          description="Estás a punto de descartar todas las modificaciones realizadas en esta sesión. Esta acción no se puede deshacer."
          initialDurationMs={2000}
          options={[
            {
              label: "Cancelar",
              color: "gray",
              onClick: closePanel
            },
            {
              label: "Sí, descartar",
              color: "red",
              onClick: () => {
                console.log("Cambios descartados");
                closePanel();
              }
            }
          ]}
        />
      </ModalOverlay>
    </>
  );
};
