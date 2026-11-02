import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Select } from '../components/ui/Select';
import { SearchInput } from '../components/ui/SearchInput';
import { EmptyState } from '../components/ui/EmptyState';
import { LoadingSpinner } from '../components/ui/LoadingSpinner';
import { Pagination } from '../components/ui/Pagination';
import { ModalOverlay } from '../components/layout/ModalOverlay';
import { ContactCard } from '../modules/contacts/ContactCard';
import { ContactProfilePanel } from '../modules/contacts/ContactProfilePanel';
import { useUsers } from '../hooks/useUsers';
import { useCampuses, useStructures } from '../hooks/useCampus';
import {
  useCreateMeeting,
  useOfficeHours,
  useTeacherAvailability,
  useTeacherMeetings,
} from '../hooks/useSchedule';
import { useAuthState } from '../states/authState';
import { Role } from '../constants/role';
import type { UserIdentity } from '../interfaces/identities/UserIdentity';
import type { OfficeHourDto, DayOfWeekName } from '../dtos/schedule/OfficeHourDto';
import {
  addDays,
  formatClock,
  formatLongDate,
  formatOfficeHour,
  sortOfficeHours,
  startOfDay,
  type BookingSlot,
} from '../utils/schedule';

import SearchIcon from '../assets/svg/icons/icon_search.svg?react';
import BuildingIcon from '../assets/svg/icons/icon_building.svg?react';
import CalendarIcon from '../assets/svg/icons/icon_calendar.svg?react';
import FilterIcon from '../assets/svg/icons/icon_filter.svg?react';

const PAGE_SIZE = 10;
const BOOKING_DAYS_AHEAD = 14;

const DAY_FILTER_OPTIONS: { value: string; label: string }[] = [
  { value: '', label: 'Todos los días' },
  { value: 'Monday', label: 'Lunes' },
  { value: 'Tuesday', label: 'Martes' },
  { value: 'Wednesday', label: 'Miércoles' },
  { value: 'Thursday', label: 'Jueves' },
  { value: 'Friday', label: 'Viernes' },
  { value: 'Saturday', label: 'Sábado' },
];

const AVAILABILITY_OPTIONS: { value: string; label: string }[] = [
  { value: 'todos', label: 'Todos los profesores' },
  { value: 'con-horario', label: 'Con horario de atención' },
  { value: 'sin-horario', label: 'Sin horario registrado' },
];

export const ContactsView = () => {
  const navigate = useNavigate();
  const currentUser = useAuthState((state) => state.user);

  const [searchQuery, setSearchQuery] = useState('');
  const [campusId, setCampusId] = useState('');
  const [structureId, setStructureId] = useState('');
  const [dayFilter, setDayFilter] = useState('');
  const [availabilityFilter, setAvailabilityFilter] = useState('todos');
  const [page, setPage] = useState(1);

  const [selectedTeacher, setSelectedTeacher] = useState<UserIdentity | null>(null);
  const [bookingSuccess, setBookingSuccess] = useState<string | null>(null);

  const {
    data: users = [],
    isLoading: isLoadingUsers,
    isError: isUsersError,
    error: usersError,
  } = useUsers();

  const { data: allOfficeHours = [], isLoading: isLoadingOfficeHours } = useOfficeHours();
  const { data: campuses = [] } = useCampuses();
  const { data: structures = [] } = useStructures();

  const dateRange = useMemo(() => {
    const fromDate = startOfDay(new Date());
    const toDate = addDays(fromDate, BOOKING_DAYS_AHEAD);
    return {
      from: fromDate.toISOString(),
      to: toDate.toISOString(),
    };
  }, []);

  const {
    data: teacherAvailability,
    isLoading: isLoadingAvailability,
  } = useTeacherAvailability(selectedTeacher?.id);

  const {
    data: teacherMeetings = [],
    isLoading: isLoadingMeetings,
  } = useTeacherMeetings(selectedTeacher?.id, dateRange.from, dateRange.to);

  const createMeeting = useCreateMeeting();

  const structureNames = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.name])),
    [structures],
  );

  const structureCampusMap = useMemo(
    () => new Map(structures.map((structure) => [structure.id, structure.campusId])),
    [structures],
  );

  const teachers = useMemo(
    () => users.filter((user) => user.role === Role.Teacher && !user.isSuspended),
    [users],
  );

  const officeHoursByTeacher = useMemo(() => {
    const map = new Map<string, OfficeHourDto[]>();
    allOfficeHours.forEach((block) => {
      const list = map.get(block.teacherRefId) ?? [];
      list.push(block);
      map.set(block.teacherRefId, list);
    });
    map.forEach((blocks, key) => {
      map.set(key, sortOfficeHours(blocks));
    });
    return map;
  }, [allOfficeHours]);

  const campusOptions = useMemo(
    () => [
      { value: '', label: 'Todos los campus' },
      ...campuses.map((campus) => ({ value: campus.id, label: campus.name })),
    ],
    [campuses],
  );

  const structureOptions = useMemo(
    () => [
      { value: '', label: 'Todos los edificios' },
      ...structures
        .filter((structure) => !campusId || structure.campusId === campusId)
        .map((structure) => ({ value: structure.id, label: structure.name })),
    ],
    [structures, campusId],
  );

  const searchSuggestions = useMemo(
    () =>
      teachers.map((teacher) => ({
        value: teacher.id,
        label: teacher.name,
      })),
    [teachers],
  );

  const filteredTeachers = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();

    return teachers.filter((teacher) => {
      const blocks = officeHoursByTeacher.get(teacher.id) ?? [];

      if (query) {
        const matchesName = teacher.name.toLowerCase().includes(query);
        const matchesEmail = teacher.email.toLowerCase().includes(query);
        if (!matchesName && !matchesEmail) return false;
      }

      if (availabilityFilter === 'con-horario' && blocks.length === 0) return false;
      if (availabilityFilter === 'sin-horario' && blocks.length > 0) return false;

      if (dayFilter) {
        const hasDay = blocks.some((block) => block.dayOfWeek === (dayFilter as DayOfWeekName));
        if (!hasDay) return false;
      }

      if (structureId) {
        const hasStructure = blocks.some((block) => block.structureRefId === structureId);
        if (!hasStructure) return false;
      } else if (campusId) {
        const hasCampus = blocks.some(
          (block) =>
            block.structureRefId && structureCampusMap.get(block.structureRefId) === campusId,
        );
        if (!hasCampus) return false;
      }

      return true;
    });
  }, [
    teachers,
    officeHoursByTeacher,
    searchQuery,
    availabilityFilter,
    dayFilter,
    structureId,
    campusId,
    structureCampusMap,
  ]);

  const totalPages = Math.max(1, Math.ceil(filteredTeachers.length / PAGE_SIZE));
  const activePage = Math.min(page, totalPages);
  const paginatedTeachers = useMemo(
    () =>
      filteredTeachers.slice((activePage - 1) * PAGE_SIZE, activePage * PAGE_SIZE),
    [filteredTeachers, activePage],
  );

  const getTeacherPrimaryOffice = (teacherId: string): string => {
    const blocks = officeHoursByTeacher.get(teacherId) ?? [];
    for (const block of blocks) {
      if (block.structureRefId && structureNames.has(block.structureRefId)) {
        return structureNames.get(block.structureRefId)!;
      }
    }
    return 'Ubicación por confirmar';
  };

  const getTeacherScheduleSummary = (teacherId: string): string => {
    const blocks = officeHoursByTeacher.get(teacherId) ?? [];
    if (blocks.length === 0) return 'Sin horario de atención registrado';
    const first = formatOfficeHour(blocks[0]);
    return blocks.length > 1 ? `${first} (+${blocks.length - 1} más)` : first;
  };

  const handleSearchChange = (value: string) => {
    setSearchQuery(value);
    setPage(1);
  };

  const handleCampusChange = (value: string) => {
    setCampusId(value);
    setStructureId('');
    setPage(1);
  };

  const handleStructureChange = (value: string) => {
    setStructureId(value);
    setPage(1);
  };

  const handleDayChange = (value: string) => {
    setDayFilter(value);
    setPage(1);
  };

  const handleAvailabilityChange = (value: string) => {
    setAvailabilityFilter(value);
    setPage(1);
  };

  const handleOpenProfile = (teacher: UserIdentity) => {
    createMeeting.reset();
    setBookingSuccess(null);
    setSelectedTeacher(teacher);
  };

  const handleCloseProfile = () => {
    setSelectedTeacher(null);
    setBookingSuccess(null);
    createMeeting.reset();
  };

  const handleBookSlot = ({
    slot,
    durationMinutes,
  }: {
    slot: BookingSlot;
    durationMinutes: number;
  }) => {
    if (!selectedTeacher || !currentUser) return;

    setBookingSuccess(null);
    createMeeting.mutate(
      {
        teacherRefId: selectedTeacher.id,
        studentRefId: currentUser.id,
        structureRefId: slot.structureRefId,
        scheduledAt: slot.start.toISOString(),
        durationMinutes,
      },
      {
        onSuccess: () => {
          setBookingSuccess(
            `Reunión agendada para el ${formatLongDate(slot.start)} a las ${formatClock(slot.start)} (${durationMinutes} min).`,
          );
        },
      },
    );
  };

  const selectedTeacherOfficeHours = useMemo(() => {
    if (!selectedTeacher) return [];
    if (teacherAvailability?.availableBlocks) {
      return teacherAvailability.availableBlocks;
    }
    return officeHoursByTeacher.get(selectedTeacher.id) ?? [];
  }, [selectedTeacher, teacherAvailability, officeHoursByTeacher]);

  const isLoading = isLoadingUsers || isLoadingOfficeHours;

  return (
    <div className="p-6 min-h-screen bg-page-dark flex flex-col gap-6">
      <div className="bg-page-dark py-2 px-4 flex flex-col gap-4">
        <div className="flex flex-wrap items-end justify-end gap-4">
          <div className="w-80">
            <SearchInput
              label="Búsqueda"
              placeholder="Buscar profesor por nombre o correo..."
              value={searchQuery}
              onChange={handleSearchChange}
              icon={<SearchIcon className="w-5 h-5 text-gray-500" />}
              options={searchSuggestions}
            />
          </div>

          <div className="w-72">
            <Select
              label="Campus"
              options={campusOptions}
              value={campusId}
              onChange={handleCampusChange}
              icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <div className="w-72">
            <Select
              label="Edificio"
              options={structureOptions}
              value={structureId}
              onChange={handleStructureChange}
              icon={<BuildingIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>
        </div>

        <div className="flex flex-wrap items-end justify-end gap-4 pt-2">
          <div className="w-60">
            <Select
              label="Día de atención"
              options={DAY_FILTER_OPTIONS}
              value={dayFilter}
              onChange={handleDayChange}
              icon={<CalendarIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>

          <div className="w-72">
            <Select
              label="Disponibilidad"
              options={AVAILABILITY_OPTIONS}
              value={availabilityFilter}
              onChange={handleAvailabilityChange}
              icon={<FilterIcon className="w-5 h-5 text-gray-700" />}
            />
          </div>
        </div>
      </div>

      <div className="flex-1 flex items-start gap-6">
        {isLoading ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <LoadingSpinner size="lg" text="Cargando directorio de profesores..." />
          </div>
        ) : isUsersError ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState
              message={usersError?.message ?? 'No se pudieron cargar los profesores.'}
            />
          </div>
        ) : filteredTeachers.length === 0 ? (
          <div className="flex-1 flex items-center justify-center p-12">
            <EmptyState message="No hay profesores que coincidan con los filtros seleccionados." />
          </div>
        ) : (
          <>
            <div className="flex-1 grid grid-cols-[repeat(auto-fill,minmax(min(100%,38rem),38rem))] justify-center content-start gap-6">
              {paginatedTeachers.map((teacher) => (
                <ContactCard
                  key={teacher.id}
                  className="!w-full max-w-[38rem] min-h-[17rem]"
                  name={teacher.name}
                  role="Profesor"
                  email={teacher.email}
                  office={getTeacherPrimaryOffice(teacher.id)}
                  scheduleSummary={getTeacherScheduleSummary(teacher.id)}
                  photoUrl={teacher.avatar}
                  onInfoClick={() => handleOpenProfile(teacher)}
                />
              ))}
            </div>

            <Pagination
              currentPage={activePage}
              totalPages={totalPages}
              onPageChange={setPage}
              className="sticky top-6"
            />
          </>
        )}
      </div>

      <ModalOverlay isOpen={!!selectedTeacher} onClose={handleCloseProfile}>
        {selectedTeacher && (
          <ContactProfilePanel
            teacherId={selectedTeacher.id}
            currentUserId={currentUser?.id}
            name={selectedTeacher.name}
            role="Profesor"
            department="Docente UCT"
            office={getTeacherPrimaryOffice(selectedTeacher.id)}
            email={selectedTeacher.email}
            photoUrl={selectedTeacher.avatar}
            officeHours={selectedTeacherOfficeHours}
            meetings={teacherMeetings}
            structureNames={structureNames}
            isLoadingSchedule={isLoadingAvailability || isLoadingMeetings}
            isBooking={createMeeting.isPending}
            bookingError={createMeeting.error?.message ?? null}
            bookingSuccess={bookingSuccess}
            onBookSlot={handleBookSlot}
            onViewOffice={() => {
              handleCloseProfile();
              navigate('/map');
            }}
            onClose={handleCloseProfile}
          />
        )}
      </ModalOverlay>
    </div>
  );
};


