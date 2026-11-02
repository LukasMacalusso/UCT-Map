import { useMemo, useState } from 'react';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { Button } from '../components/ui/Button';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { EmptyState } from '../components/ui/EmptyState';
import { Pagination } from '../components/ui/Pagination';
import { ModalOverlay } from '../components/layout/ModalOverlay';
import {
  UserProfilePanel,
  type UserProfileMeetingItem,
} from '../modules/global/UserProfilePanel';
import { UserManagementCard } from '../modules/admin/UserManagementCard';
import { useToggleUserSuspension, useUpdateUserRole, useUsers } from '../hooks/useUsers';
import { useReports } from '../hooks/useReports';
import { useLostObjectsByIds } from '../hooks/useLostObjects';
import { useAllMeetings } from '../hooks/useSchedule';
import { useStructures } from '../hooks/useCampus';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import {
  LOST_OBJECT_STATUS_COLORS,
  LOST_OBJECT_STATUS_LABELS,
} from '../constants/lostObjectsStatus';
import {
  TICKET_STATUS_COLORS,
  TICKET_STATUS_LABELS,
} from '../constants/ticketStatus';
import { formatRelativeTime } from '../utils/date';
import {
  formatClock,
  formatLongDate,
  MEETING_STATUS_COLORS,
  MEETING_STATUS_LABELS,
  parseScheduleDate,
} from '../utils/schedule';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';
import type { ObjectReportCardProps } from '../modules/objects/ObjectReportCard';
import type { IncidentCardProps } from '../modules/incidents/IncidentCard';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import CategoryIcon from '../assets/svg/icons/icon_category_cube.svg?react';
import RefreshIcon from '../assets/svg/icons/icon_repeat.svg?react';

const PAGE_SIZE = 20;
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const labelOf = (user: UserIdentity) => `${user.name} (${user.email})`;

export const AdministrationView = () => {
  const currentUserId = useAuthState((state) => state.user?.id);

  const { data: users = [], isLoading, isFetching, error: usersError, refetch } = useUsers();
  const updateUserRole = useUpdateUserRole();
  const toggleUserSuspension = useToggleUserSuspension();
  const [actionError, setActionError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedRole, setSelectedRole] = useState('todos');
  const [currentPage, setCurrentPage] = useState(1);
  const [profileUser, setProfileUser] = useState<UserIdentity | null>(null);

  const roleOptions = [
    { value: 'todos', label: 'Todos los roles' },
    { value: Role.Student, label: 'Estudiante' },
    { value: Role.Teacher, label: 'Profesor' },
    { value: Role.Admin, label: 'Administrador' },
    { value: Role.ComplaintsOfficer, label: 'Encargado de Incidentes' },
    { value: Role.ObjectsOfficer, label: 'Encargado de Objetos' },
    { value: 'suspendidos', label: 'Suspendidos' },
  ];

  const error = actionError ?? (usersError ? 'No se pudieron cargar los usuarios. Intenta nuevamente.' : null);
  const isRefreshing = isFetching && !isLoading;

  const handleRefresh = () => {
    setActionError(null);
    refetch();
  };

  const handleToggleSuspension = (userId: string, isSuspended: boolean) => {
    setActionError(null);
    toggleUserSuspension.mutate(
      { userId, isSuspended },
      { onError: () => setActionError('No se pudo cambiar el estado de la cuenta.') },
    );
  };

  const handleRoleChange = (userId: string, newRole: Role) => {
    const previousRole = users.find((u) => u.id === userId)?.role;
    if (!previousRole || previousRole === newRole) return;

    setActionError(null);
    updateUserRole.mutate(
      { userId, role: newRole },
      { onError: () => setActionError('No se pudo cambiar el rol del usuario.') },
    );
  };

  const query = searchQuery.trim().toLowerCase();
  const filteredUsers = users.filter((user) => {
    const matchesFilter =
      selectedRole === 'todos' ||
      (selectedRole === 'suspendidos' ? !!user.isSuspended : user.role === selectedRole);
    const matchesSearch = !query || labelOf(user).toLowerCase().includes(query);
    return matchesFilter && matchesSearch;
  });

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const activePage = Math.min(currentPage, totalPages);
  const paginatedUsers = filteredUsers.slice(
    (activePage - 1) * PAGE_SIZE,
    activePage * PAGE_SIZE
  );

  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
    setCurrentPage(1);
  };

  const handleRoleFilterChange = (value: string) => {
    setSelectedRole(value);
    setCurrentPage(1);
  };

  const handleViewProfile = (userId: string) => {
    setProfileUser(users.find((u) => u.id === userId) ?? null);
  };

  const shouldFetchProfileData = Boolean(profileUser && UUID_REGEX.test(profileUser.id));

  const { data: structures = [] } = useStructures(undefined, shouldFetchProfileData);
  const { data: reportsPage } = useReports(
    {
      userRefId: profileUser?.id,
      sortBy: 'ReportedAt',
      descending: true,
      page: 1,
      pageSize: 10,
    },
    shouldFetchProfileData,
  );

  const profileLostObjectIds = useMemo(
    () =>
      (reportsPage?.items ?? [])
        .filter((report) => report.userRefId === profileUser?.id && Boolean(report.lostObjectId))
        .map((report) => report.lostObjectId!),
    [reportsPage?.items, profileUser?.id],
  );

  const { data: profileLostObjects = [] } = useLostObjectsByIds(
    profileLostObjectIds,
    shouldFetchProfileData,
  );
  const { data: allMeetings = [] } = useAllMeetings(shouldFetchProfileData);

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const usersById = useMemo(
    () => new Map(users.map((item) => [item.id, item])),
    [users],
  );

  const profileIncidents = useMemo<IncidentCardProps[]>(() => {
    if (!profileUser || !reportsPage?.items) return [];
    return reportsPage.items
      .filter((report) => report.userRefId === profileUser.id && report.complaintDetails != null)
      .map((report) => ({
        location:
          (report.structureRefId && structureNames.get(report.structureRefId)) ||
          'Sin ubicación',
        status: TICKET_STATUS_LABELS[report.ticketType] ?? 'SIN ESTADO',
        statusColor: TICKET_STATUS_COLORS[report.ticketType] ?? 'gray',
        title: report.complaintDetails?.title ?? 'Reporte sin título',
        reporterName: profileUser.name,
        reportTime: formatRelativeTime(report.reportedAt),
        reporterAvatar: profileUser.avatar,
        description: report.complaintDetails?.description ?? 'Sin descripción',
      }));
  }, [profileUser, reportsPage, structureNames]);

  const profileObjects = useMemo<ObjectReportCardProps[]>(() => {
    if (!profileUser) return [];
    return profileLostObjects.map((lostObject) => ({
      title: lostObject.title,
      status: LOST_OBJECT_STATUS_LABELS[lostObject.status],
      statusColor: LOST_OBJECT_STATUS_COLORS[lostObject.status],
      photoUrl: lostObject.photoUrl,
      building: structureNames.get(lostObject.structureId) ?? 'Sin ubicación',
      actions: [
        {
          title: `Reportado por ${profileUser.name}`,
          subtitle: formatRelativeTime(lostObject.reportedAt),
          avatarSrc: profileUser.avatar,
        },
      ],
    }));
  }, [profileUser, profileLostObjects, structureNames]);

  const profileMeetings = useMemo<UserProfileMeetingItem[]>(() => {
    if (!profileUser) return [];
    return allMeetings
      .filter((meeting) => meeting.studentRefId === profileUser.id)
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
        };
      });
  }, [profileUser, allMeetings, usersById, structureNames]);

  return (
    <div className="p-6 min-h-screen bg-page-dark flex flex-col gap-6">

      {/* Filter Bar */}
      <div className="bg-page-dark py-2 px-4 flex flex-col gap-4">
        <div className="flex flex-wrap items-end justify-end gap-4">

          {/* User Search */}
          <div className="w-80">
            <SearchInput
              label="Búsqueda"
              placeholder="Buscar por nombre o correo..."
              value={searchQuery}
              onChange={handleSearchChange}
              icon={<SearchIcon className="w-5 h-5 text-gray-500" />}
              showSuggestions={false}
            />
          </div>

          {/* Role Filter */}
          <div className="w-72">
            <Select
              label="Rol"
              options={roleOptions}
              value={selectedRole}
              onChange={handleRoleFilterChange}
              icon={<CategoryIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <Button
            variant="solid"
            color="blue"
            size="md"
            className="font-bold tracking-wide shadow-md hover:scale-105 transition-transform whitespace-nowrap !w-auto px-6 h-[50px] flex items-center justify-center gap-2"
            onClick={handleRefresh}
            disabled={isRefreshing || isLoading}
          >
            <RefreshIcon className={`w-5 h-5 ${isRefreshing ? 'animate-spin' : ''}`} />
            ACTUALIZAR
          </Button>

        </div>
      </div>

      {/* Results Area */}
      <div className="flex-1 flex flex-col gap-4 max-w-5xl w-full mx-auto">

        {error && (
          <div className="text-red-50 text-sm font-medium bg-red-500/90 p-3 rounded-2xl">
            {error}
          </div>
        )}

        {isLoading ? (
          <LoadingSpinner size="lg" text="Cargando usuarios..." className="mt-16" />
        ) : filteredUsers.length === 0 ? (
          <EmptyState message="No se encontraron usuarios" />
        ) : (
          <div className="flex items-start gap-6">
            <div className="flex-1 flex flex-col gap-4 min-w-0">
              {paginatedUsers.map((user) => (
                <UserManagementCard
                  key={user.id}
                  id={user.id}
                  name={user.name}
                  email={user.email}
                  avatarSrc={user.avatar}
                  role={user.role}
                  isSuspended={user.isSuspended}
                  canToggleSuspension={user.id !== currentUserId}
                  onViewProfile={handleViewProfile}
                  onRoleChange={handleRoleChange}
                  onToggleSuspension={handleToggleSuspension}
                />
              ))}
            </div>

            <Pagination
              currentPage={activePage}
              totalPages={totalPages}
              onPageChange={setCurrentPage}
              className="sticky top-6"
            />
          </div>
        )}

      </div>

      <ModalOverlay isOpen={!!profileUser} onClose={() => setProfileUser(null)}>
        {profileUser && (
          <UserProfilePanel
            name={profileUser.name}
            email={profileUser.email}
            role={profileUser.role}
            photoUrl={profileUser.avatar}
            isOwnProfile={profileUser.id === currentUserId}
            objectReports={profileObjects}
            incidentReports={profileIncidents}
            requestedMeetings={profileMeetings}
            onClose={() => setProfileUser(null)}
          />
        )}
      </ModalOverlay>

    </div>
  );
};
