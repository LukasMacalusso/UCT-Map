import { useMemo } from 'react';
import { useUiState } from '../../states/uiState';
import { useAuthState } from '../../states/authState';
import { ModalOverlay } from './ModalOverlay';
import {
  UserProfilePanel,
  type UserProfileMeetingItem,
} from '../../modules/global/UserProfilePanel';
import { useNavigate, useLocation } from 'react-router-dom';
import { useReports } from '../../hooks/useReports';
import { useLostObjectsByIds } from '../../hooks/useLostObjects';
import {
  useAllMeetings,
  useStudentMeetings,
  useUpdateMeetingStatus,
  useCancelMeeting,
} from '../../hooks/useSchedule';
import { useStructures } from '../../hooks/useCampus';
import { useUsers } from '../../hooks/useUsers';
import { Role } from '../../constants/role';
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
  addDays,
  formatClock,
  formatLongDate,
  MEETING_STATUS_COLORS,
  MEETING_STATUS_LABELS,
  parseScheduleDate,
  startOfDay,
} from '../../utils/schedule';
import type { ObjectReportCardProps } from '../../modules/objects/ObjectReportCard';
import type { IncidentCardProps } from '../../modules/incidents/IncidentCard';

export const GlobalModals = () => {
  const activePanel = useUiState((state) => state.activePanel);
  const closePanel = useUiState((state) => state.closePanel);
  const editorToast = useUiState((state) => state.editorToast);
  const user = useAuthState((state) => state.user);
  const logout = useAuthState((state) => state.logout);
  const navigate = useNavigate();
  const location = useLocation();
  const updateMeetingStatus = useUpdateMeetingStatus();
  const cancelMeeting = useCancelMeeting();

  const isProfileOpen = activePanel === 'userProfile' && !!user;
  const isAdmin = user?.role === Role.Admin;

  const { data: structures = [] } = useStructures(undefined, isProfileOpen);
  const { data: users = [] } = useUsers(isProfileOpen);

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

  const studentMeetingsRange = useMemo(() => {
    const today = startOfDay(new Date());
    return {
      from: addDays(today, -30).toISOString(),
      to: addDays(today, 60).toISOString(),
    };
  }, []);

  const { data: allMeetings = [] } = useAllMeetings(isProfileOpen && isAdmin);
  const { data: studentMeetingsData } =
    useStudentMeetings?.(
      user?.id,
      studentMeetingsRange.from,
      studentMeetingsRange.to,
      isProfileOpen && !isAdmin,
    ) ?? { data: undefined };

  const meetingsSource = isAdmin
    ? allMeetings
    : (studentMeetingsData?.meetings ?? allMeetings);

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
    return meetingsSource
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
  }, [user, meetingsSource, usersById, structureNames]);

  const admissionYear = useMemo(() => {
    if (!user?.registeredAt) return undefined;
    const year = new Date(user.registeredAt).getFullYear();
    return Number.isNaN(year) ? undefined : String(year);
  }, [user]);

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
            onCancelMeeting={(meetingId) => {
              if (cancelMeeting?.mutate) {
                cancelMeeting.mutate(meetingId);
              }
              updateMeetingStatus.mutate({ id: meetingId, status: 'Cancelled' });
            }}
            isCancellingMeeting={
              updateMeetingStatus.isPending || Boolean(cancelMeeting?.isPending)
            }
          />
        )}
      </ModalOverlay>

      {/* Floating Toast Notification for General Views */}
      {editorToast && !location.pathname.startsWith('/edition') && (
        <div className="fixed bottom-6 right-6 z-50 pointer-events-none">
          <div
            key={editorToast.id}
            className={`animate-toast-expo flex items-center px-4 py-2.5 rounded-2xl text-xs font-bold shadow-2xl border backdrop-blur-md will-change-transform ${
              editorToast.type === 'error'
                ? 'bg-red-50/95 border-red-200 text-page-red'
                : editorToast.type === 'info'
                ? 'bg-blue-50/95 border-blue-200 text-page-blue'
                : 'bg-emerald-50/95 border-emerald-200 text-emerald-800'
            }`}
          >
            <span>{editorToast.message}</span>
          </div>
        </div>
      )}
    </>
  );
};
